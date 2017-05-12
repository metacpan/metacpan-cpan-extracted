package PICA::Modification;
{
  $PICA::Modification::VERSION = '0.16';
}
#ABSTRACT: Idempotent modification of an identified PICA+ record

use strict;
use warnings;
use v5.10;

use parent 'Exporter';

use PICA::Record 0.584;
use Scalar::Util qw(blessed);
use Text::Diff ();

our @ATTRIBUTES = qw(id iln epn del add);


sub new {
	my $class = shift;
	my $attributes = @_ % 2 ? (blessed $_[0] ? $_[0]->attributes : $_[0]) : {@_};

    no strict 'refs';
    my $self = bless {
		map { $_ => $attributes->{$_} } @{ $class.'::ATTRIBUTES' }
	}, $class;

	$self->check;
}


sub attributes {
	my $self = shift;

    no strict 'refs';
	return { map { $_ => $self->{$_} } @{ ref($self).'::ATTRIBUTES' } };
}


sub error {
    my $self = shift;

    return (scalar keys %{$self->{errors}}) unless @_;
    
    my $attribute = shift;
    return $self->{errors}->{$attribute} unless @_;

    my $message = shift;
    $self->{errors}->{$attribute} = $message;

    return $message;
}


sub check {
	my $self = shift;

	$self->{errors} = { };

	foreach my $attr (@ATTRIBUTES) {
		my $value = $self->{$attr} // '';
	    $value =~ s/^\s+|\s+$//g;
		$self->{$attr} = $value;
	}

	$self->{ppn} = '';
	$self->{dbkey} = '';
    if ($self->{id} =~ /^(([a-z]([a-z0-9-]?[a-z0-9]+))*):ppn:(\d+\d*[Xx]?)$/) {
        $self->{ppn}   = uc($4) if defined $4;
        $self->{dbkey} = lc($1) if defined $1;
    } elsif ($self->{id} eq '') {
        $self->error( id => 'missing record identifier' );
    } else {
        $self->error( id => 'malformed record identifier' );
    }

    $self->error( iln => "malformed ILN" ) unless $self->{iln} =~ /^\d*$/;
    $self->error( epn => "malformed EPN" ) unless $self->{epn} =~ /^\d*$/;

    my %must_delete;

    if ($self->{add}) {
        my $pica = eval { PICA::Record->new( $self->{add} ) };
        if ($pica) {
			$self->error( iln => 'missing ILN for add' )
				if !$self->{iln} and $pica->field(qr/^1/);
			$self->error( epn => 'missing EPN for add' )
				if !$self->{epn} and $pica->field(qr/^2/);
            $pica->sort;
            foreach ($pica->fields) {
                my $tag = $_->tag;
                # TODO: remove occurrence from level 2 tags
                $must_delete{$tag} = 1;
            }
	    	$self->{add} = "$pica";
			chomp $self->{add};
        } else {
            $self->error( add => "malformed fields to add" );
        }
    }

	my @del = grep { $_ !~ /^\s*$/ } split(/\s*,\s*/, $self->{del});

	$self->error( del => 'malformed fields to remove' )
        if grep { $_ !~  qr{^[012]\d\d[A-Z@](/\d\d)?$} } @del;

	$self->error( epn => 'missing EPN for remove' )
		if !$self->{epn} and grep { /^2/ } @del;

	$self->error( iln => 'missing ILN for remove' )
		if !$self->{iln} and grep { /^1/ } @del;

    delete $must_delete{$_} for @del;
    if (%must_delete) {
        $self->error( del => 'fields to add must also be deleted' );
    }

    $self->{del} = join (',', sort @del);

    if (!$self->{add} and !$self->{del} and !$self->error('del')) {
        $self->error( del => 'edit must not be empty' );
    }

    if ( !$self->error('del') ) {
        my @bad = grep { /^(003@|101@|203@)/; } @del;
        if (@bad) {
            $self->error( del => 'must not modify field: '.join(', ',@bad) );
        }
	}

    return $self;
}


sub apply {
    my ($self, $pica, %args) = @_;

    return if $self->error;

	if (!$pica) {
		$self->error( id => 'record not found' );
		return;
	}
	if ( defined $pica->ppn and $pica->ppn ne $self->{ppn} ) {
	    $self->error( id => 'PPN does not match' );
		return;
    }

    my $add = PICA::Record->new( $self->{add} || '' );
    my $del = [ split ',', $self->{del} ];

    my @level0 = grep /^0/, @$del;
    my @level1 = grep /^1/, @$del;
    my @level2 = grep /^2/, @$del;

    my $iln = $self->{iln};
    my $epn = $self->{epn};

    # Level 0
    my $result = $pica->main;
    $result->remove( @level0 ) if @level0;
    $result->append( $add->main );    

    # Level 1
	if (@level1 and !$pica->holdings($iln)) {
		$self->error('iln', 'ILN not found');
		return;
    }

    foreach my $h ( $pica->holdings ) {
        if ($iln and $iln eq ($h->iln // '')) {
            @level1 = map { $_ =~ qr{/} ? $_ : ($_,"$_/..") } @level1; 
            $h->remove( @level1 );
            $h->append( $add->field(qr/^1/) );
        } 
        $result->append( $h->fields );

	    # TODO: Level 2
    }
	
    $result->sort;

    return $result;
}



sub diff {
    my ($self, $record, $context) = @_;

    my $result = $self->apply( $record ) or return;

    $context //= (scalar $record->fields + scalar $result->fields);
    
    my $diff = Text::Diff::diff(
        \($record->string),
        \($result->string),
        {CONTEXT => $context}
    );

    $diff =~ s/^@.*$ \n//xgm;

    return $diff;
}

1;




__END__
=pod

=head1 NAME

PICA::Modification - Idempotent modification of an identified PICA+ record

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  use PICA::Modification;

  # delete field '0123A' from record 'foo:ppn:123'
  my $mod = PICA::Modification->new( 
      id => 'foo:ppn:123', del => '0123A' 
  );

  $after = $mod->apply( $before );

=head1 DESCRIPTION

PICA::Modification models a modification of an identified PICA+ record
(L<PICA::Record>). The modification consist of the following attributes:

=over 4

=item add

A stringified PICA+ record with fields to be added.

=item del

A comma-separated list of PICA+ field tags to be removed. All tags of fields 
to be added must also be included for deletion so modifications are idempotent.

=item id

The fully qualified record identifier of form C<PREFIX:ppn:PPN>.

=item iln

The ILN of level 1 record to modify. Only required for modifications that
include level 1 fields.

=item epn

The EPN of the level 2 record to modify. Only required for modifications that
include level 2 fields.

=back

A modification instance may be malformed. A mapping from malformed attributes
to error messages is stored together with the PICA::Modification object.

PICA::Modification is extended to L<PICA::Modification::Request>. Collections
of modifications can be stored in a L<PICA::Modification::Queue>.

=head1 METHODS

=head2 new ( %attributes | { %attributes } | $modification )

Creates a new modification from attributes, given as hash, as hash reference or
as another L<PICA::Modification>. The modification is L<checked|/check> on
creation, so all attributes are normalized, missing attributes are set to the
empty string and invalid attributes result in L<errors|/error>.

=head2 attributes

Returns a new hash reference with attributes of this modification.

=head2 error( [ $attribute [ => $message ] ] )

Gets or sets an error message connected to an attribute. Without arguments this
method returns the current number of errors.

=head2 check

Normalizes and checks all attributes. Missing values are set to the empty string
and invalid attributes result in L<errors|/error>. Returns the modification.

=head2 apply ( $pica )

Applies the modification on a given PICA+ record and returns the resulting
record as L<PICA::Record> or C<undef> on malformed modifications. 

Only edits at level 0 and level 1 are supported by now.

PPN/ILN/EPN must match or an L<error|/error> is set.

=head2 diff ( $record [, $context ] )

Applies the modification to a given PICA+ record and returns a diff on success.
The context attribute specifies the number of fields before/after each deleted
or added field. If undefines, all fields are included in the diff.

=head1 SEE ALSO

See L<PICA::Record> for information about PICA+ record format.

=encoding utf-8

=head1 AUTHOR

Jakob Voß <voss@gbv.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jakob Voß.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

