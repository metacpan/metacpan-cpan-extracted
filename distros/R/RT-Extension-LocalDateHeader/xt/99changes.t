use Test::More;
eval 'use Test::CPAN::Changes';
plan skip_all => 'Test::CPAN::Changes required for this test' if $@;
plan undef;
use_ok('RT::Extension::LocalDateHeader');
changes_file_ok('Changes',{version => $RT::Extension::LocalDateHeader::VERSION});
done_testing;
