# include <string.h>
# include "Pcore/Util/Path.h"

struct Tokens {
    size_t len;
    int is_dots;
    U8 *token;
};

void destroyPcoreUtilPath (PcoreUtilPath *path) {
    Safefree(path->path);
    Safefree(path->volume);
    Safefree(path->dirname);
    Safefree(path->filename);
    Safefree(path->filename_base);
    Safefree(path->suffix);
    Safefree(path);
}

PcoreUtilPath *parse (const char *buf, size_t buf_len) {
    PcoreUtilPath *res;
    Newx(res, 1, PcoreUtilPath);

    res->is_abs = 0;
    res->path_len = 0;
    res->path = NULL;
    res->volume_len = 0;
    res->volume = NULL;
    res->dirname_len = 0;
    res->dirname = NULL;
    res->filename_len = 0;
    res->filename = NULL;
    res->filename_base_len = 0;
    res->filename_base = NULL;
    res->suffix_len = 0;
    res->suffix = NULL;

    // buf is not empty
    if (buf_len) {
        U8 prefix[3];
        size_t prefix_len = 0;
        size_t i = 0;

        // parse leading "/"
        if (buf[0] == '/' || buf[0] == '\\') {
            prefix[0] = '/';
            prefix_len = 1;
            i = 1;

            res->is_abs = 1;
        }

# ifdef WIN32

        // parse windows volume
        else if ( buf_len >= 2 && buf[1] == ':' && ( buf[2] == '/' || buf[2] == '\\' ) && isalpha(buf[0]) ) {
            prefix[0] = tolower(buf[0]);
            prefix[1] = ':';
            prefix[2] = '/';
            prefix_len = 3;
            i = 3;

            res->is_abs = 1;
            res->volume_len = 1;
            Newx(res->volume, 1, char);
            res->volume[0] = prefix[0];
        }
# endif

        struct Tokens tokens [ (buf_len / 2) + 1 ];
        size_t tokens_len = 0;
        size_t tokens_total_len = 0;

        U8 token[ buf_len ];
        size_t token_len = 0;

        for ( ; i < buf_len; i++ ) {
            int process_token = 0;

            // slash char
            if ( buf[i] == '/' || buf[i] == '\\' ) {
                process_token = 1;
            }
            else {

                // add char to the current token
                token[ token_len++ ] = buf[i];

                // last char
                if (i + 1 == buf_len) process_token = 1;
            }

            // current token is completed, process token
            if (process_token && token_len) {
                int skip_token = 0;
                int is_dots = 0;

                // skip "." token
                if ( token_len == 1 && token[0] == '.' ) {
                    skip_token = 1;
                }

                // process ".." token
                else if ( token_len == 2 && token[0] == '.' && token[1] == '.' ) {
                    is_dots = 1;

                    // has previous token
                    if (tokens_len) {

                        // previous token is NOT "..", remove previous token
                        if (!tokens[tokens_len - 1].is_dots) {
                            skip_token = 1;

                            Safefree(tokens[tokens_len - 1].token);
                            tokens_total_len -= tokens[tokens_len - 1].len;

                            tokens_len -= 1;
                        }
                    }

                    // has no previous token
                    else {

                        // path is absolute, skip ".." token
                        if (prefix_len) skip_token = 1;
                    }
                }

                // store token
                if (!skip_token) {

                    // last token, and token is not "." or ".." or last char is not "/" or "\" - last token is filename
                    if (i + 1 == buf_len && !is_dots && buf[i] != '/' && buf[i] != '\\') {
                        res->filename_len = token_len;
                        Newx(res->filename, token_len, char);
                        memcpy(res->filename, token, token_len);

                        int has_suffix = 0;

                        // parse filename_base, suffix
                        for (size_t i = token_len - 1; i > 0; i--) {

                            // not-leading dot found
                            if (token[i] == '.') {
                                has_suffix = 1;

                                res->suffix_len = token_len - i - 1;
                                Newx(res->suffix, res->suffix_len, char);
                                memcpy(res->suffix, token + i + 1, res->suffix_len);

                                res->filename_base_len = i;
                                Newx(res->filename_base, res->filename_base_len, char);
                                memcpy(res->filename_base, token, res->filename_base_len);

                                break;
                            }
                        }

                        // filename_base = filename if !has_suffix
                        if (!has_suffix) {
                            res->filename_base_len = token_len;
                            Newx(res->filename_base, token_len, char);
                            memcpy(res->filename_base, token, token_len);
                        }
                    }

                    Newx(tokens[tokens_len].token, token_len, U8);
                    memcpy(tokens[tokens_len].token, token, token_len);

                    tokens[tokens_len].len = token_len;
                    tokens[tokens_len].is_dots = is_dots;

                    tokens_total_len += token_len;
                    tokens_len++;
                }

                token_len = 0;
            }
        }

        // calculate path length
        res->path_len = prefix_len + tokens_total_len;
        if (tokens_len) res->path_len += tokens_len - 1;

        // path is not empty
        if (res->path_len) {
            Newx(res->path, res->path_len, char);
            size_t dst_pos = 0;

            // add prefix
            if (prefix_len) {
                dst_pos += prefix_len;
                memcpy(res->path, &prefix, prefix_len);
            }

            // join tokens
            for ( size_t i = 0; i < tokens_len; i++ ) {
                memcpy(res->path + dst_pos, tokens[i].token, tokens[i].len);

                Safefree(tokens[i].token);

                dst_pos += tokens[i].len;

                // add "/" if token is not last
                if (i < tokens_len - 1) res->path[dst_pos++] = '/';
            }

            // path has filename, dirname = path - filename
            if (res->filename_len) {
                res->dirname_len = res->path_len - res->filename_len;
                if (res->dirname_len > 1) res->dirname_len -= 1;

                if(res->dirname_len) {
                    Newx(res->dirname, res->dirname_len, char);
                    Copy(res->path, res->dirname, res->dirname_len, char);
                }
            }

            // path has no filename, dirname = path
            else {
                res->dirname_len = res->path_len;
                Newx(res->dirname, res->dirname_len, char);
                Copy(res->path, res->dirname, res->dirname_len, char);
            }
        }
    }

    if (!res->path_len) {
        res->path_len = 1;
        Newx(res->path, res->path_len, char);
        res->path[0] = '.';
    }

    if (!res->dirname_len) {
        res->dirname_len = 1;
        Newx(res->dirname, res->dirname_len, char);
        res->dirname[0] = '.';
    }

    return res;
}
