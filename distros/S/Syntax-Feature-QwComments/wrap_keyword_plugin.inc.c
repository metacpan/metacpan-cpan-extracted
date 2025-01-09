// `wrap_keyword_plugin` makes modifying `PL_keyword_plugin` thread safe.
// However, `wrap_keyword_plugin` and the associated mutex
// `KEYWORD_PLUGIN_MUTEX_LOCK` are only available since 5.27.6.
// We'll use `OP_CHECK_MUTEX_LOCK` in lieu of `KEYWORD_PLUGIN_MUTEX_LOCK`,
// although that mutex is only available since 5.15.8.
#ifndef wrap_keyword_plugin
#   ifdef OP_CHECK_MUTEX_LOCK
#      define KEYWORD_PLUGIN_MUTEX_LOCK OP_CHECK_MUTEX_LOCK
#      define KEYWORD_PLUGIN_MUTEX_UNLOCK OP_CHECK_MUTEX_UNLOCK
#   else
#      define KEYWORD_PLUGIN_MUTEX_LOCK ((void)0)
#      define KEYWORD_PLUGIN_MUTEX_UNLOCK ((void)0)
#   endif
STATIC void wrap_keyword_plugin( pTHX_ Perl_keyword_plugin_t new_plugin, Perl_keyword_plugin_t *old_plugin_p ) {
#define wrap_keyword_plugin( a, b ) wrap_keyword_plugin( aTHX_ a, b )
   if ( *old_plugin_p )
      return;

   KEYWORD_PLUGIN_MUTEX_LOCK;

   if ( !*old_plugin_p ) {
      *old_plugin_p = PL_keyword_plugin;
      PL_keyword_plugin = new_plugin;
   }

   KEYWORD_PLUGIN_MUTEX_UNLOCK;
}
#endif
