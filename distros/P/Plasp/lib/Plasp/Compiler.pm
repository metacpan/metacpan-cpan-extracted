package Plasp::Compiler;


use Carp;
use File::Slurp qw(read_file);
use Plasp::Exception::NotFound;

use Moo::Role;
use Sub::HandlesVia;
use Types::Standard qw(HashRef);

with 'Plasp::Parser';

requires 'parse_file';

=head1 NAME

Plasp::Compiler - Role for Plasp providing code compilation

=head1 SYNOPSIS

  package Plasp;
  with 'Plasp::Parser', 'Plasp::Compiler';

  sub execute {
    my ($self, $scriptref) = @_;
    my $parsed = $self->parse($scriptref);
    my $subid = $self->compile($parsed->{data});
    eval { &$subid };
  }

=head1 DESCRIPTION

This class implements the ability to compile parsed ASP code.

=cut

has '_compiled_includes' => (
    is          => 'rw',
    isa         => HashRef,
    default     => sub { {} },
    handles_via => 'Hash',
    handles     => {
        _get_compiled_include => 'get',
        _add_compiled_include => 'set',
        _include_is_compiled  => 'exists',
    },
);

has '_registered_includes' => (
    is          => 'rw',
    isa         => HashRef,
    default     => sub { {} },
    handles_via => 'Hash',
    handles     => {
        _add_registered_include => 'set',
        _include_is_registered  => 'exists',
    },
);

=head1 METHODS

=over

=item $self->compile($scriptref, $subid)

Takes a C<$scriptref> that has been parsed and C<$subid> for the name of the
subroutine to compile the code into. Returns

=cut

sub compile {
    my ( $self, $scriptref, $subid ) = @_;

    my $package = $self->GlobalASA->package;
    $self->_undefine_sub( $subid );

    my $code = join( ' ;; ',
        "package $package;",    # for no sub closure
        "no strict;",
        "sub $subid { ",
        "package $package;",    # for sub closure
        $$scriptref,
        '}',
    );
    $code =~ /^(.*)$/s;         # Realized this is for untainting
    $code = $1;

    no warnings;
    eval $code;    ## no critic (BuiltinFunctions::ProhibitStringyEval)
    if ( $@ ) {
        $self->error( "Error on compilation of $subid: $@" ); # don't throw error, so we can throw die later
        $self->_undefine_sub( $subid );
        return;
    } else {
        $self->register_include( $scriptref );
        return $subid;
    }
}

=item $self->compile_include($include)

Takes an C<$include> file. This will search for the file in C<IncludesDir> and
parse it, and assign it a C<$subid> based on it's filename.

=cut

sub compile_include {
    my ( $self, $include ) = @_;

    my $file = $self->search_includes_dir( $include );
    unless ( $file ) {
        $self->error( "Error in compilation: $include not found" );
        return;
    }

    return $self->compile_file( $file );
}

=item $self->compile_file($file)

Takes an C<$file> assuming it exists. This will search for the file in
C<IncludesDir> and parse it, and assign it a C<$subid> based on it's filename.

=cut

sub compile_file {
    my ( $self, $file ) = @_;

    Plasp::Exception::NotFound->throw unless -r $file;

    my $id    = $self->file_id( $file );
    my $subid = join( '', $self->GlobalASA->package, '::', $id, 'xINC' );

    return $self->_get_compiled_include( $subid ) if $self->_include_is_compiled( $subid );

    my $parsed_object = $self->parse_file( $file );
    return unless $parsed_object;

    my %compiled_object = (
        mtime => time(),
        perl  => $parsed_object->{data},
        file  => $file,
    );

    if ( $parsed_object->{is_perl}
        && ( my $code = $self->compile( $parsed_object->{data}, $subid ) ) ) {
        $compiled_object{is_perl} = 1;
        $compiled_object{code}    = $code;
    } elsif ( $parsed_object->{is_raw} ) {
        $compiled_object{is_raw} = 1;
        $compiled_object{code}   = $parsed_object->{data};
    } else {
        return;
    }

    # for a returned code ref, don't cache
    $self->_add_compiled_include( $subid => \%compiled_object )
        if ( $subid && !$self->_parse_for_subs( $parsed_object->{data} ) );

    return \%compiled_object;
}

=item $self->register_include($scriptref)

Registers the file file of any calls to C<< $Response->Include() >> so as to
prevent infinite recursion

=cut

sub register_include {
    my ( $self, $scriptref ) = @_;

    my $copy = $$scriptref;
    $copy =~ s/\$Response\-\>Include\([\'\"]([^\$]+?)[\'\"]/
        {
            my $include = $1;
            # prevent recursion
            unless( $self->_include_is_registered( $include ) ) {
                $self->_add_registered_include( $include => 1 );
                eval { $self->compile_include( $include ); };
                $self->log->warn( "Register include $include with error: $@" ) if $@;
            }
            '';
        } /exsgi;
}

# This is how CHAMAS gets a subroutined destroyed
sub _undefine_sub {
    my ( $self, $subid ) = @_;
    if ( my $code = \&{$subid} ) {
        undef( &$code );
    }
}

1;

=back

=head1 SEE ALSO

=over

=item * L<Plasp>

=item * L<Plasp::Parser>

=back
