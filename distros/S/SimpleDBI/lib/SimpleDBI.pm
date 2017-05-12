#ABSTRACT: some function base DBI
package SimpleDBI;
our $VERSION=0.02;

sub new {
    my ( $self, %opt ) = @_;
    $opt{sep} //= ',';
    $opt{write_head} //= 1;
    $opt{skip_head} //= 0;
    $opt{host} //= 'localhost';
    $opt{enable_utf8} //=1;
    $opt{charset} //='utf8';

    my $module = "SimpleDBI::$opt{type}";
    eval "require $module;";
    my $r = bless \%opt, $module;
    $r->{dbh} = $r->connect_db(%opt);
    return $r;
} ## end sub
1;
