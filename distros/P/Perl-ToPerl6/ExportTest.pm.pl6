#use Exporter;
require Exporter:from<Perl5>;

our @EXPORT = ( 'export_me_always', ( ) );
our @EXPORT_OK = qw ( export_me_silently );

#push @EXPORT, qw( a b c );
#unshift @EXPORT, qw( a b c );
#@EXPORT = ( @EXPORT, qw( a b c ) );

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

sub export_me_always is export (:MANDATORY) { }
sub export_me_silently is export { }
