use Test::More tests => 3;

BEGIN { use_ok "Sys::Trace" }
BEGIN { use_ok "Sys::Trace::Impl::Strace" }
BEGIN { use_ok "Sys::Trace::Impl::Ktrace" }

