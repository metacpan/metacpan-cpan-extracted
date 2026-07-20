#!perl
##----------------------------------------------------------------------------
## Person Name Format - t/00.load.t
##----------------------------------------------------------------------------
use v5.10.1;
use strict;
use warnings;
use lib './lib';
use Test::More;

# To generate the list of modules:
# find ./lib -type f -name "*.pm" -print | xargs perl -lE 'my @f=sort(@ARGV); for(@f) { s,./lib/,,; s,\.pm$,,; s,/,::,g; substr( $_, 0, 0, q{use_ok( ''} ); $_ .= q{'' );}; say $_; }'
BEGIN
{
    use_ok( 'PersonName::Format' );
    use_ok( 'PersonName::Format::Compiled' );
    use_ok( 'PersonName::Format::Exception' );
    use_ok( 'PersonName::Format::FieldModifier' );
    use_ok( 'PersonName::Format::Generic' );
    use_ok( 'PersonName::Format::Name' );
    use_ok( 'PersonName::Format::NullObject' );
    use_ok( 'PersonName::Format::PP' );
    use_ok( 'PersonName::Format::Pattern' );
    use_ok( 'PersonName::Format::SimpleName' );
}

can_ok( 'PersonName::Format', qw(
    compile
    data
    display_order
    displayOrder
    formality
    format
    format_to_parts
    formatToParts
    length
    locale
    resolved_options
    resolvedOptions
    surname_all_caps
    surnameAllCaps
    usage
) );

diag( "XS loaded: ", ( $PersonName::Format::IsPurePerl ? 'no (pure-Perl fallback)' : 'yes' ) );

done_testing();

__END__
