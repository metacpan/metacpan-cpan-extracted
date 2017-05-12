use strict;
use warnings;

package PowerShell::Pipeline;
$PowerShell::Pipeline::VERSION = '1.00';
# ABSTRACT: Wraps powershell cmdlet pipeline
# PODNAME: PowerShell::Pipeline

use Carp;
use PowerShell::Cmdlet;

sub new {
    return bless( {}, shift )->_init(@_);
}

sub add {
    my ( $self, $cmdlet, @parameters ) = @_;

    delete( $self->{command} );    #clear cached command

    unless ( ref($cmdlet) && $cmdlet->isa('PowerShell::Cmdlet') ) {
        $cmdlet = PowerShell::Cmdlet->new($cmdlet);
        foreach my $parameter (@parameters) {
            my $ref = ref($parameter);
            if ( !$ref || $ref eq 'SCALAR' ) {
                $cmdlet->parameter($parameter);
            }
            elsif ( $ref eq 'ARRAY' && scalar(@$parameter) == 2 ) {
                $cmdlet->parameter(@$parameter);
            }
            else {
                croak('inline parameters must be name value array ref, or scalar value');
            }
        }
    }

    push( @{ $self->{pipeline} }, $cmdlet );

    return $self;
}

sub _init {
    my ($self) = @_;

    $self->{pipeline} = [];

    return $self;
}

sub command {
    my ($self) = @_;
    unless ( $self->{command} ) {
        $self->{command} = join( '|', map { $_->command() } @{ $self->{pipeline} } );
    }
    return $self->{command};
}

1;

__END__

=pod

=head1 NAME

PowerShell::Pipeline - Wraps powershell cmdlet pipeline

=head1 VERSION

version 1.00

=head1 SYNOPSIS

    use PowerShell::Pipeline;

    # Minimally
    my $pipeline = PowerShell::Pipeline->new()
        ->add('Mount-DiskImage', 
            ['Image', 'C:\\tmp\\foo.iso'], 
            ['StorageType', 'ISO'])
        ->add('Get-Volume');
        ->add('Select', ['ExpandProperty', 'Name']);

    # Then execute with powershell
    PowerShell->new($pipeline)->execute();

    # Or just print it out
    print('pipeline [', $pipeline->command(), "]\n");

=head1 DESCRIPTION

Represents a pipeline of cmdlets.

=head1 CONSTRUCTORS

=head2 new()

Creates a new pipeline for cmdlets.

=head1 METHODS

=head2 add($cmdlet, [@parameters])

Adds C<$cmdlet> to the end of the pipeline.  If C<$cmdlet> is a string, it
will be passed on to the constructor of C<PowerShell::Cmdlet> and 
C<parameter> will be called for each of the supplied parameters.

=head2 command()

Returns a string form of the pipeline.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PowerShell|PowerShell>

=item *

L<PowerShell|PowerShell>

=item *

L<PowerShell::Cmdlet|PowerShell::Cmdlet>

=item *

L<https://msdn.microsoft.com/en-us/powershell/scripting/powershell-scripting|https://msdn.microsoft.com/en-us/powershell/scripting/powershell-scripting>

=back

=cut
