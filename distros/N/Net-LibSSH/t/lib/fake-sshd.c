/* A one-connection fake SSH server for t/12-shell-dialog.t and
   t/13-algorithm-options.t, built on libssh's own server API and compiled by
   t/lib/FakeSSHD.pm against the same Alien::libssh the module links.

   Why it exists: OpenSSH's sshd offers auth "none" only to an account with an
   empty password, which an unprivileged test cannot create, and it will not
   offer the legacy algorithms old devices speak. This server lets any client
   in without authentication and then plays the "User Name:" / "Password:"
   dialog of a switch on an interactive shell.

   usage: fake-sshd PORT [--kex=LIST] [--hostkeys=LIST] [--ciphers=LIST]
                         [--hmac=LIST] [--hostkey-type=ed25519|rsa]

   stdout: "KEY <type> <base64>" (the host public key), then "READY".
   It serves exactly one connection and exits. */

#include <libssh/libssh.h>
#include <libssh/server.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static void
send_str(ssh_channel ch, const char *s)
{
    ssh_channel_write(ch, s, (uint32_t) strlen(s));
}

/* Read one line (up to CR or LF); 0 on end of input. */
static int
read_line(ssh_channel ch, char *buf, size_t size)
{
    size_t n = 0;
    char c;
    while (ssh_channel_read(ch, &c, 1, 0) == 1) {
        if (c == '\r' || c == '\n') {
            buf[n] = '\0';
            return 1;
        }
        if (n + 1 < size)
            buf[n++] = c;
    }
    return 0;
}

static void
dialog(ssh_channel ch, const char *term, int cols, int rows)
{
    char user[128], pass[128], cmd[256], out[512];

    for (;;) {
        send_str(ch, "\r\nUser Name:");
        if (!read_line(ch, user, sizeof(user)))
            return;
        send_str(ch, "\r\nPassword:");
        if (!read_line(ch, pass, sizeof(pass)))
            return;
        if (strcmp(user, "cisco") == 0 && strcmp(pass, "secret") == 0)
            break;
    }
    send_str(ch, "\r\nswitch#");
    while (read_line(ch, cmd, sizeof(cmd))) {
        if (strncmp(cmd, "echo ", 5) == 0) {
            snprintf(out, sizeof(out), "\r\n%s\r\nswitch#", cmd + 5);
            send_str(ch, out);
        } else if (strcmp(cmd, "slow") == 0) {
            sleep(2);
            send_str(ch, "\r\ndone\r\nswitch#");
        } else if (strcmp(cmd, "pty") == 0) {
            snprintf(out, sizeof(out), "\r\n%s %dx%d\r\nswitch#",
                     term, cols, rows);
            send_str(ch, out);
        } else if (strcmp(cmd, "logout") == 0) {
            send_str(ch, "\r\nbye\r\n");
            ssh_channel_send_eof(ch);
            ssh_channel_close(ch);
            return;
        } else {
            send_str(ch, "\r\n% Unrecognized command\r\nswitch#");
        }
    }
}

int
main(int argc, char **argv)
{
    const char *kex = NULL, *hostkeys = NULL, *ciphers = NULL, *hmac = NULL;
    enum ssh_keytypes_e ktype = SSH_KEYTYPE_ED25519;
    int bits = 0, port, i;

    if (argc < 2)
        return 2;
    port = atoi(argv[1]);
    for (i = 2; i < argc; i++) {
        if (strncmp(argv[i], "--kex=", 6) == 0)           kex = argv[i] + 6;
        else if (strncmp(argv[i], "--hostkeys=", 11) == 0) hostkeys = argv[i] + 11;
        else if (strncmp(argv[i], "--ciphers=", 10) == 0)  ciphers = argv[i] + 10;
        else if (strncmp(argv[i], "--hmac=", 7) == 0)      hmac = argv[i] + 7;
        else if (strcmp(argv[i], "--hostkey-type=rsa") == 0) {
            ktype = SSH_KEYTYPE_RSA;
            bits = 2048;
        }
    }

    ssh_bind bind = ssh_bind_new();
    ssh_session session = ssh_new();
    ssh_key key = NULL;
    if (!bind || !session || ssh_pki_generate(ktype, bits, &key) != SSH_OK)
        return 3;

    char *b64 = NULL;
    ssh_key pub = NULL;
    if (ssh_pki_export_privkey_to_pubkey(key, &pub) != SSH_OK
        || ssh_pki_export_pubkey_base64(pub, &b64) != SSH_OK)
        return 3;
    printf("KEY %s %s\n", ssh_key_type_to_char(ssh_key_type(pub)), b64);
    ssh_string_free_char(b64);
    ssh_key_free(pub);

    if (ssh_bind_options_set(bind, SSH_BIND_OPTIONS_BINDADDR, "127.0.0.1") != SSH_OK
        || ssh_bind_options_set(bind, SSH_BIND_OPTIONS_BINDPORT, &port) != SSH_OK
        || ssh_bind_options_set(bind, SSH_BIND_OPTIONS_IMPORT_KEY, key) != SSH_OK)
        return 3;
    if (kex && ssh_bind_options_set(bind, SSH_BIND_OPTIONS_KEY_EXCHANGE, kex) != SSH_OK) {
        fprintf(stderr, "server: kex rejected: %s\n", ssh_get_error(bind));
        return 4;
    }
    if (hostkeys && ssh_bind_options_set(bind, SSH_BIND_OPTIONS_HOSTKEY_ALGORITHMS, hostkeys) != SSH_OK) {
        fprintf(stderr, "server: hostkeys rejected: %s\n", ssh_get_error(bind));
        return 4;
    }
    if (ciphers
        && (ssh_bind_options_set(bind, SSH_BIND_OPTIONS_CIPHERS_C_S, ciphers) != SSH_OK
            || ssh_bind_options_set(bind, SSH_BIND_OPTIONS_CIPHERS_S_C, ciphers) != SSH_OK)) {
        fprintf(stderr, "server: ciphers rejected: %s\n", ssh_get_error(bind));
        return 4;
    }
    if (hmac
        && (ssh_bind_options_set(bind, SSH_BIND_OPTIONS_HMAC_C_S, hmac) != SSH_OK
            || ssh_bind_options_set(bind, SSH_BIND_OPTIONS_HMAC_S_C, hmac) != SSH_OK)) {
        fprintf(stderr, "server: hmac rejected: %s\n", ssh_get_error(bind));
        return 4;
    }

    if (ssh_bind_listen(bind) != SSH_OK)
        return 3;
    printf("READY\n");
    fflush(stdout);

    if (ssh_bind_accept(bind, session) != SSH_OK
        || ssh_handle_key_exchange(session) != SSH_OK) {
        fprintf(stderr, "server: handshake failed: %s\n", ssh_get_error(session));
        /* Keep the socket open a little: closing at once, with the client's
           next packet still unread, sends a reset that can overtake the
           client's own "no match" diagnosis and replace it with a bare
           "Socket error". The test kills this process when it is done. */
        sleep(5);
        return 5;
    }

    ssh_channel ch = NULL;
    char term[64] = "none";
    int cols = 0, rows = 0, shell = 0;
    ssh_message msg;
    while (!shell && (msg = ssh_message_get(session)) != NULL) {
        int type = ssh_message_type(msg), sub = ssh_message_subtype(msg);
        if (type == SSH_REQUEST_AUTH && sub == SSH_AUTH_METHOD_NONE) {
            ssh_message_auth_reply_success(msg, 0);
        } else if (type == SSH_REQUEST_AUTH) {
            ssh_message_auth_set_methods(msg, SSH_AUTH_METHOD_NONE);
            ssh_message_reply_default(msg);
        } else if (type == SSH_REQUEST_CHANNEL_OPEN && sub == SSH_CHANNEL_SESSION) {
            ch = ssh_message_channel_request_open_reply_accept(msg);
        } else if (type == SSH_REQUEST_CHANNEL && sub == SSH_CHANNEL_REQUEST_PTY) {
            const char *t = ssh_message_channel_request_pty_term(msg);
            snprintf(term, sizeof(term), "%s", t ? t : "");
            cols = ssh_message_channel_request_pty_width(msg);
            rows = ssh_message_channel_request_pty_height(msg);
            ssh_message_channel_request_reply_success(msg);
        } else if (type == SSH_REQUEST_CHANNEL && sub == SSH_CHANNEL_REQUEST_SHELL) {
            ssh_message_channel_request_reply_success(msg);
            shell = 1;
        } else {
            ssh_message_reply_default(msg);
        }
        ssh_message_free(msg);
    }
    if (ch && shell)
        dialog(ch, term, cols, rows);

    ssh_disconnect(session);
    ssh_bind_free(bind);
    ssh_free(session);
    return 0;
}
