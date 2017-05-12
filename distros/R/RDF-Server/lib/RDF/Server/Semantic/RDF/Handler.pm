package RDF::Server::Semantic::RDF::Handler;

use Moose;
with 'RDF::Server::Role::Handler';

use RDF::Server::Types qw( Model );
use RDF::Server::Semantic::RDF::Types qw( RDFCodeRef );

has 'model' => (
    is => 'ro',
    isa => Model,
    coerce => 1,
    predicate => 'has_model'
);

has '+handlers' => (
    isa => RDFCodeRef,
    coerce => 1
);

around handles_path => sub {
    my($method, $self, $prefix, $p, @rest) = @_;

    my(@r) = $self -> $method( $prefix, $p, @rest );
    if(@r && $r[0] eq $self) {
#        print STDERR "in handles_path: p = $p; prefix = [$prefix]\n";
#        print STDERR "path_prefix: ", $self -> path_prefix, "\n";
        my $u = "/$p/";
        my $pr = "/" . $self -> path_prefix . "/";
        $u =~ s{/+}{}g;
        $pr =~ s{/+}{}g;
        if( $u eq $pr ) {
            return($self -> model, '') if $self -> has_model;;
        }
    }
    return @r if @r;
    return;
};

1;

__END__
