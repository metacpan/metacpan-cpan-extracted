
/*
 * Copyright (C) 2003  Sam Horrocks
 * 
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 */

/* Based on apache's mod_cgi.c */

/* ====================================================================
 * The Apache Software License, Version 1.1
 *
 * Copyright (c) 2000-2003 The Apache Software Foundation.  All rights
 * reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in
 *    the documentation and/or other materials provided with the
 *    distribution.
 *
 * 3. The end-user documentation included with the redistribution,
 *    if any, must include the following acknowledgment:
 *       "This product includes software developed by the
 *        Apache Software Foundation (http://www.apache.org/)."
 *    Alternately, this acknowledgment may appear in the software itself,
 *    if and wherever such third-party acknowledgments normally appear.
 *
 * 4. The names "Apache" and "Apache Software Foundation" must
 *    not be used to endorse or promote products derived from this
 *    software without prior written permission. For written
 *    permission, please contact apache@apache.org.
 *
 * 5. Products derived from this software may not be called "Apache",
 *    nor may "Apache" appear in their name, without prior written
 *    permission of the Apache Software Foundation.
 *
 * THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESSED OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE APACHE SOFTWARE FOUNDATION OR
 * ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
 * USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 * ====================================================================
 *
 * This software consists of voluntary contributions made by many
 * individuals on behalf of the Apache Software Foundation.  For more
 * information on the Apache Software Foundation, please see
 * <http://www.apache.org/>.
 *
 * Portions of this software are based upon public domain software
 * originally written at the National Center for Supercomputing Applications,
 * University of Illinois, Urbana-Champaign.
 */

/*
 * http_script: keeps all script-related ramblings together.
 * 
 * Compliant to CGI/1.1 spec
 * 
 * Adapted by rst from original NCSA code by Rob McCool
 *
 * Apache adds some new env vars; REDIRECT_URL and REDIRECT_QUERY_STRING for
 * custom error responses, and DOCUMENT_ROOT because we found it useful.
 * It also adds SERVER_ADMIN - useful for scripts to know who to mail when 
 * they fail.
 */

#include "perperl.h"

extern char **environ;

module AP_MODULE_DECLARE_DATA persistentperl_module;
static request_rec *global_r;
#if APR_HAS_THREADS
static apr_thread_mutex_t *perperl_mutex;
#endif

/* Configuration */

/* set_option is used as a callback in the cgi_cmds array */
static const char *set_option(cmd_parms *cmd, void *dummy, const char *arg) {
    /* cmd->info is a pointer to the OptRec */
    perperl_opt_set((OptRec*)cmd->info, arg);
    return NULL;
}

/* Include the definition of the cgi_cmds array */
#include "mod_persistentperl2_cmds.c"

/* This must get called after "set_option" calls above.  This is the current
 * apache behaviour, so it works.
 */
static void one_time_init(void) {
    static const char *prog_argv[2];

    /* Initialize perperl options */
    prog_argv[0] = "";
    prog_argv[1] = NULL;
    perperl_opt_init(
	(const char * const *)prog_argv, (const char * const *)environ
    );
    perperl_opt_save();
}

/* End of Configuration */

/* Read and discard the data in the brigade produced by a CGI script */
static void discard_script_output(apr_bucket_brigade *bb);

/* KLUDGE --- for back-combatibility, we don't have to check ExecCGI
 * in ScriptAliased directories, which means we need to know if this
 * request came through ScriptAlias or not... so the Alias module
 * leaves a note for us.
 */

static int is_scriptaliased(request_rec *r)
{
    const char *t = apr_table_get(r->notes, "alias-forced-type");
    return t && (!strcasecmp(t, "persistentperl-script"));
}

static int log_scripterror(request_rec *r, int ret,
                           apr_status_t rv, char *error)
{
    int log_flags = rv ? APLOG_ERR : APLOG_ERR;

    ap_log_rerror(APLOG_MARK, log_flags, rv, r, 
                  "%s: %s", error, r->filename);
    return ret;
}

/* Soak up stderr from a script and redirect it to the error log. 
 */
static void log_script_err(request_rec *r, apr_file_t *script_err)
{
    char argsbuffer[HUGE_STRING_LEN];
    char *newline;

    while (apr_file_gets(argsbuffer, HUGE_STRING_LEN,
                         script_err) == APR_SUCCESS) {
        newline = strchr(argsbuffer, '\n');
        if (newline) {
            *newline = '\0';
        }
        ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r, 
                      "%s", argsbuffer);            
    }
}

/* Cleanup for our script file handles */
static apr_status_t file_cleanup(void *thefile) {
    apr_file_t *file = thefile;
    int fd;

    if (apr_os_file_get(&fd, file) == APR_SUCCESS && fd >= 0)
	return apr_file_close((apr_file_t*)thefile);
    else
	return APR_SUCCESS;
}

static apr_status_t file_close(apr_pool_t *p, apr_file_t *file) {
    return apr_pool_cleanup_run(p, file, file_cleanup);
}

static apr_status_t run_cgi_child(apr_file_t **script_out,
                                  apr_file_t **script_in,
                                  apr_file_t **script_err, 
                                  const char *command,
                                  const char * const argv[],
                                  request_rec *r,
                                  apr_pool_t *p)
{
    apr_status_t rc = APR_SUCCESS;
    PersistentBuf buf;
    int socks[NUMFDS];
    char **env;

#if NUMFDS != 3
    /* We can't handle NUMFDS != 3 */
    --INCORRECT_NUMFDS;
#endif
    
    /* Can't handle argv[0] null */
    if (argv[0] == NULL) {
	ap_log_rerror(APLOG_MARK, APLOG_ERR, 0, r, "argv[0] passed in as null");
	return APR_EGENERAL;
    }

    /* Get environment */
    env = ap_create_environment(p, r->subprocess_env);

#if APR_HAS_THREADS
    /* Persistent routines are not thread safe */
    if ((rc = apr_thread_mutex_lock(perperl_mutex)) != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, rc, r,
	    "Cannot lock perperl_mutex");
	return rc;
    }
#endif

    /* One-time initialization */
    {
	static int did_this;
	if (!did_this) {
	    one_time_init();
	    did_this = 1;
	}
    }

    /* Copy request_rec to global */
    global_r = r;

    /* May have been a while since we ran last */
    perperl_util_time_invalidate();

    /* Restore our original option values */
    perperl_opt_restore();

    /* Set script argv */
    perperl_opt_set_script_argv(argv);

    /* Get string of env/argv data to send */
    perperl_frontend_mkenv(
	(const char * const *)env, argv, HUGE_STRING_LEN, &buf, 1
    );

    /* Connect up to a persistentperl backend, creating a new one if necessary */
    if (!perperl_frontend_connect(socks, NULL))
	rc = APR_EGENERAL;

#if APR_HAS_THREADS
    /* All done with thread-unsafe perperl routines */
    if ((rc = apr_thread_mutex_unlock(perperl_mutex)) != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR, rc, r,
	    "Cannot unlock perperl_mutex");
	return rc;
    }
#endif

    if (rc == APR_SUCCESS) {
	int i, flags[NUMFDS];
	apr_file_t **files[NUMFDS];

	files[0] = script_out; files[1] = script_in; files[2] = script_err;
	flags[0] = APR_WRITE;  flags[1] = APR_READ;  flags[2] = APR_READ;

	/* Set up files */
	for (i = 0; i < NUMFDS; ++i) {
	    apr_os_file_put(files[i], socks+i, flags[i], p);
	    apr_pool_cleanup_register(p, files[i][0],
		file_cleanup, file_cleanup);
	    /* XXX - there should be way to set a timeout on this file */
	    /* files[i][0]->timeout = r->server->timeout * APR_USEC_PER_SEC; */
	}

	/* Send over env */
	rc = apr_file_write_full(*script_out, buf.buf, buf.len, NULL);
    }

    perperl_free(buf.buf);
    return (rc);
}


static apr_status_t default_build_command(const char **cmd, const char ***argv,
                                          request_rec *r, apr_pool_t *p)
{
    int numwords, x, idx;
    char *w;
    const char *args = NULL;

    {
        *cmd = r->filename;
        args = r->args;
        /* Do not process r->args if they contain an '=' assignment 
         */
        if (r->args && r->args[0] && !ap_strchr_c(r->args, '=')) {
            args = r->args;
        }
    }

    if (!args) {
        numwords = 1;
    }
    else {
        /* count the number of keywords */
        for (x = 0, numwords = 2; args[x]; x++) {
            if (args[x] == '+') {
                ++numwords;
            }
        }
    }
    /* Everything is - 1 to account for the first parameter 
     * which is the program name.
     */ 
    if (numwords > APACHE_ARG_MAX - 1) {
        numwords = APACHE_ARG_MAX - 1;    /* Truncate args to prevent overrun */
    }
    *argv = apr_palloc(p, (numwords + 2) * sizeof(char *));
    (*argv)[0] = *cmd;
    for (x = 1, idx = 1; x < numwords; x++) {
        w = ap_getword_nulls(p, &args, '+');
        ap_unescape_url(w);
        (*argv)[idx++] = ap_escape_shell_cmd(p, w);
    }
    (*argv)[idx] = NULL;

    return APR_SUCCESS;
}

static void discard_script_output(apr_bucket_brigade *bb)
{
    apr_bucket *e;
    const char *buf;
    apr_size_t len;
    apr_status_t rv;
    APR_BRIGADE_FOREACH(e, bb) {
        if (APR_BUCKET_IS_EOS(e)) {
            break;
        }
        rv = apr_bucket_read(e, &buf, &len, APR_BLOCK_READ);
        if (rv != APR_SUCCESS) {
            break;
        }
    }
}

static int cgi_handler(request_rec *r)
{
    int nph;
    const char *argv0;
    const char *command;
    const char **argv;
    apr_file_t *script_out = NULL, *script_in = NULL, *script_err = NULL;
    apr_bucket_brigade *bb;
    apr_bucket *b;
    int is_included;
    int seen_eos, child_stopped_reading;
    apr_pool_t *p;
    apr_status_t rv;
    int is_threaded;

    if(strcmp(r->handler, CGI_MAGIC_TYPE) && strcmp(r->handler, "persistentperl-script"))
        return DECLINED;

    is_included = !strcmp(r->protocol, "INCLUDED");

    p = r->main ? r->main->pool : r->pool;

    if (r->method_number == M_OPTIONS) {
        /* 99 out of 100 CGI scripts, this is all they support */
        r->allowed |= (AP_METHOD_BIT << M_GET);
        r->allowed |= (AP_METHOD_BIT << M_POST);
        return DECLINED;
    }

    argv0 = apr_filename_of_pathname(r->filename);
    nph = !(strncmp(argv0, "nph-", 4));

    if (!(ap_allow_options(r) & OPT_EXECCGI) && !is_scriptaliased(r))
        return log_scripterror(r, HTTP_FORBIDDEN, 0,
                               "Options ExecCGI is off in this directory");
    if (nph && is_included)
        return log_scripterror(r, HTTP_FORBIDDEN, 0,
                               "attempt to include NPH CGI script");

    if (r->finfo.filetype == 0)
        return log_scripterror(r, HTTP_NOT_FOUND, 0,
                               "script not found or unable to stat");
    if (r->finfo.filetype == APR_DIR)
        return log_scripterror(r, HTTP_FORBIDDEN, 0,
                               "attempt to invoke directory as script");

    if ((r->used_path_info == AP_REQ_REJECT_PATH_INFO) &&
        r->path_info && *r->path_info)
    {
        /* default to accept */
        return log_scripterror(r, HTTP_NOT_FOUND, 0,
                               "AcceptPathInfo off disallows user's path");
    }
/*
    if (!ap_suexec_enabled) {
        if (!ap_can_exec(&r->finfo))
            return log_scripterror(r, HTTP_FORBIDDEN, 0,
                                   "file permissions deny server execution");
    }

*/

#if APR_HAS_THREADS
    /* Two problems with threaded mpms:
     *
     *	Persistent routines are not thread safe.  We can workaround that with a big
     *	lock, though that may cause excessive waiting when Maxbackends
     *	is used.
     *
     *	Frontends are sent SIGALRM to wake them up, and signals don't get
     *	delivered to the waiting thread.
     */
    ap_mpm_query(AP_MPMQ_IS_THREADED, &is_threaded);
    if (is_threaded)
	return log_scripterror(r, HTTP_FORBIDDEN, 0,
	    "cannot use mod_persistentperl with a threaded mpm");
#endif

    ap_add_common_vars(r);
    ap_add_cgi_vars(r);

    /* build the command line */
    if ((rv = default_build_command(&command, &argv, r, p)) != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR|APLOG_TOCLIENT, rv, r,
                      "don't know how to spawn child process: %s", 
                      apr_filename_of_pathname(r->filename));
        return HTTP_INTERNAL_SERVER_ERROR;
    }

    /* run the script in its own process */
    if ((rv = run_cgi_child(&script_out, &script_in, &script_err,
                            command, argv, r, p)) != APR_SUCCESS) {
        ap_log_rerror(APLOG_MARK, APLOG_ERR|APLOG_TOCLIENT, rv, r,
                      "couldn't spawn child process: %s",
		      apr_filename_of_pathname(r->filename));
        return HTTP_INTERNAL_SERVER_ERROR;
    }

    /* Transfer any put/post args, CERN style...
     * Note that we already ignore SIGPIPE in the core server.
     */
    bb = apr_brigade_create(r->pool, r->connection->bucket_alloc);
    seen_eos = 0;
    child_stopped_reading = 0;
    do {
        apr_bucket *bucket;

        rv = ap_get_brigade(r->input_filters, bb, AP_MODE_READBYTES,
                            APR_BLOCK_READ, HUGE_STRING_LEN);
       
        if (rv != APR_SUCCESS) {
            return rv;
        }

        APR_BRIGADE_FOREACH(bucket, bb) {
            const char *data;
            apr_size_t len;

            if (APR_BUCKET_IS_EOS(bucket)) {
                seen_eos = 1;
                break;
            }

            /* We can't do much with this. */
            if (APR_BUCKET_IS_FLUSH(bucket)) {
                continue;
            }

            /* If the child stopped, we still must read to EOS. */
            if (child_stopped_reading) {
                continue;
            } 

            /* read */
            apr_bucket_read(bucket, &data, &len, APR_BLOCK_READ);
            
            /* Keep writing data to the child until done or too much time
             * elapses with no progress or an error occurs.
             */
            rv = apr_file_write_full(script_out, data, len, NULL);

            if (rv != APR_SUCCESS) {
                /* silly script stopped reading, soak up remaining message */
                child_stopped_reading = 1;
            }
        }
        apr_brigade_cleanup(bb);
    }
    while (!seen_eos);

    /* Is this flush really needed? */
    apr_file_flush(script_out);
    file_close(p, script_out);

    /* Handle script return... */
    if (script_in && !nph) {
        conn_rec *c = r->connection;
        const char *location;
        char sbuf[MAX_STRING_LEN];
        int ret;

        b = apr_bucket_pipe_create(script_in, c->bucket_alloc);
        APR_BRIGADE_INSERT_TAIL(bb, b);
        b = apr_bucket_eos_create(c->bucket_alloc);
        APR_BRIGADE_INSERT_TAIL(bb, b);

        if ((ret = ap_scan_script_header_err_brigade(r, bb, sbuf))) {
            return ret;
        }

        location = apr_table_get(r->headers_out, "Location");

        if (location && location[0] == '/' && r->status == 200) {
            discard_script_output(bb);
            apr_brigade_destroy(bb);
            log_script_err(r, script_err);
            /* This redirect needs to be a GET no matter what the original
             * method was.
             */
            r->method = apr_pstrdup(r->pool, "GET");
            r->method_number = M_GET;

            /* We already read the message body (if any), so don't allow
             * the redirected request to think it has one.  We can ignore 
             * Transfer-Encoding, since we used REQUEST_CHUNKED_ERROR.
             */
            apr_table_unset(r->headers_in, "Content-Length");

            ap_internal_redirect_handler(location, r);
            return OK;
        }
        else if (location && r->status == 200) {
            /* XX Note that if a script wants to produce its own Redirect
             * body, it now has to explicitly *say* "Status: 302"
             */
            discard_script_output(bb);
            apr_brigade_destroy(bb);
            return HTTP_MOVED_TEMPORARILY;
        }

        ap_pass_brigade(r->output_filters, bb);

        log_script_err(r, script_err);
        file_close(p, script_err);
    }

    if (script_in && nph) {
        conn_rec *c = r->connection;
        struct ap_filter_t *cur;
        
        /* get rid of all filters up through protocol...  since we
         * haven't parsed off the headers, there is no way they can
         * work
         */

        cur = r->proto_output_filters;
        while (cur && cur->frec->ftype < AP_FTYPE_CONNECTION) {
            cur = cur->next;
        }
        r->output_filters = r->proto_output_filters = cur;

        bb = apr_brigade_create(r->pool, c->bucket_alloc);
        b = apr_bucket_pipe_create(script_in, c->bucket_alloc);
        APR_BRIGADE_INSERT_TAIL(bb, b);
        b = apr_bucket_eos_create(c->bucket_alloc);
        APR_BRIGADE_INSERT_TAIL(bb, b);
        ap_pass_brigade(r->output_filters, bb);
    }

    return OK;                      /* NOT r->status, even if it has changed. */
}


static void register_hooks(apr_pool_t *p)
{
    apr_status_t rc;

#if APR_HAS_THREADS
    /* Initialize perperl mutex */
    rc = apr_thread_mutex_create(&perperl_mutex, APR_THREAD_MUTEX_DEFAULT, p);
    if (rc != APR_SUCCESS) {
	ap_log_perror(APLOG_MARK, APLOG_ERR, rc, p,
	    "Could not create perperl mutex");
	exit(1);
    }
#endif

    /* Put in hook for cgi_handler */
    ap_hook_handler(cgi_handler, NULL, NULL, APR_HOOK_MIDDLE);
}

module AP_MODULE_DECLARE_DATA persistentperl_module =
{
    STANDARD20_MODULE_STUFF,
    NULL,                        /* dir config creater */
    NULL,                        /* dir merger --- default is to override */
    NULL,		         /* server config */
    NULL,                        /* merge server config */
    cgi_cmds,                    /* command apr_table_t */
    register_hooks               /* register hooks */
};

/*
 * Glue functions
 */

void perperl_abort(const char *s) {
    ap_log_error(APLOG_MARK, APLOG_ERR, 0, NULL, "mod_persistentperl failed: %s", s);
    perperl_util_exit(1,0);
}

int perperl_execvp(const  char *filename, const char *const *argv)
{
    RAISE_SIGSTOP(CGI_CHILD);

#ifndef WIN32
    if (global_r)
	chdir(ap_make_dirstr_parent(global_r->pool, global_r->filename));
#endif
    apr_pool_cleanup_for_exec();
    return execvp(filename, (char *const*)argv);
}

