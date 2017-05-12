package Nephia::Incognito;
use strict;
use warnings;
use Nephia::Core;

our $SPACE = {};

sub incognito {
    my ($class, %opts) = @_;
    $opts{caller}  ||= caller();
    my $instance = Nephia::Core->new(%opts);
    $instance->export_dsl;
    my $name = $class->_incognito_namespace($instance->caller_class);
    $SPACE->{$name} = $instance;
    return $name;
}

sub unmask {
    my $class = shift;
    my $appname = shift || caller();
    my $name = $class->_incognito_namespace($appname);
    return $SPACE->{$name};
}

sub _incognito_namespace { 
    my ($class, $appname) = @_;
    'Nephia::Incognito::'.$appname;
} 

1;

__END__

=encoding utf-8

=head1 NAME

Nephia::Incognito - A mechanism that conceal a Nephia instance into namespace

=head1 DESCRIPTION

A concealer for Nephia.

=head1 SYNOPSIS

    Nephia::Incognito->incognito( caller => 'MyApp', plugins => [...], app => sub {...} );
    my $nephia_instance = Nephia::Incognito->unmask('MyApp');
    $nephia_instance->run;

=head1 METHODS

=head2 incognito

    Nephia::Incognito->incognito( %opts );

Conceal a Nephia instance into namespace. See L<Nephia::Core> about option.

=head2 unmask

    my $instance = Nephia::Incognito->unmask( $appname );

Returns a Nephia instance that has a specified appname.

=head1 AUTHOR

ytnobody E<lt>ytnobody@gmail.comE<gt>

=cut

