// Fondation core JS — no-op fallbacks overridden by others plugin when present.
// Authorization plugin (if loaded) overwrites them.
window.fondationCheckPerm  = function (perm)  { return true; };
window.fondationCheckGroup = function (group) { return true; };
