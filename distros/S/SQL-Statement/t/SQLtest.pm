################
package SQLtest;
################
use strict;
use warnings;

#use lib  qw( ../lib );
use SQL::Statement;
printf "SQL::Statement v.%s\n", $SQL::Statement::VERSION;
our ( @ISA, @EXPORT, $DEBUG, $parser, $stmt, $cache );
$cache = {};
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(&new_parser &parse &do_ &execute &fetchStr $parser $stmt);

sub new_parser
{
    $parser = (@_) ? SQL::Parser->new(@_) : SQL::Parser->new();
}

sub parse
{
    my ($sql) = @_;
    eval { $stmt = SQL::Statement->new( $sql, $parser ) };
    warn $@ if $@ and $DEBUG;
    return ($@) ? 0 : 1;
}

sub do_
{
    my ( $sql, @params ) = @_;
    @params = () unless @params;
    $stmt = SQL::Statement->new( $sql, $parser );
    eval { $stmt->execute( $cache, @params ) };
    return ($@) ? 0 : 1;
}

sub execute
{
    my @params = @_;
    @params = () unless @params;
    eval { $stmt->execute( $cache, @params ) };
    return ($@) ? 0 : 1;
}

sub fetchStr
{
    my ( $sql, @params ) = @_;
    do_( $sql, @params );
    my $str = '';
    while ( my $r = $stmt->fetch )
    {
        @$r = map { defined $_ ? $_ : '' } @$r;
        $str .= sprintf "%s^", join '~', @$r;
    }
    $str =~ s/\^$//;
    return $str;
}
1;
