# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 17-logging.t'

use strict;
use warnings;
use Test::More tests => 11;

BEGIN { use_ok('Net::Z3950::ZOOM') };

check_level("none", 0);
check_level("none,debug", 2);
check_level("none,warn", 4);
check_level("none,warn,debug", 6);
check_level("none,zoom", 8192);
check_level("none,-warn", 0);
check_level("", 2077);
check_level("-warn", 2073);
check_level("zoom", 10269);
check_level("none,zoom,fruit", 24576);

sub check_level {
    my($str, $expect) = @_;
    my $level = Net::Z3950::ZOOM::yaz_log_mask_str($str);
    ok($level == $expect, "log-level for '$str' ($level, expected $expect)");
}

# All the YAZ-logging functions other than yaz_log_mask_str() have
# side-effects, which makes them painful to write tests for.  At the
# moment, I think we have better ways to spend the time, so these
# functions remain untested:
#	int yaz_log_module_level(const char *name);
#	void yaz_log_init(int level, const char *prefix, const char *name);
#	void yaz_log_init_file(const char *fname);
#	void yaz_log_init_level(int level);
#	void yaz_log_init_prefix(const char *prefix);
#	void yaz_log_time_format(const char *fmt);
#	void yaz_log_init_max_size(int mx);
#	void yaz_log(int level, const char *str);
# But if anyone feels strongly enough about this to want to fund the
# creation of a rigorous YAZ-logging test suite, please get in touch
# :-)
