package MongoDBx::Tiny::Validator;
use strict;
use warnings;

=head1 NAME

MongoDBx::Tiny::Validator - validation on insert and update.

=cut

use MongoDBx::Tiny::Util;
use Params::Validate qw(:all);
use Carp qw(confess);
use Data::Dumper;

=head1 SUBROUTINES/METHODS

=head2 new

  $validator = MongoDBx::Tiny::Validator->new(
  	$collection_name,
  	$document,
  	$tiny,
  );

=cut

sub new {
    my $class  = shift;
    my $c_name   = shift || confess q/no collection name/;
    my $document = shift || confess q/no document/;
    my $tiny     = shift || confess q/no tiny/;
    
    return bless {
	document         => $document,
	collection_name  => $c_name,
	tiny             => $tiny,
	errors           => [],
    }, $class;
}

=head2 document, collection_name, tiny

  # alias
  $document = $validator->document;
  $collection_name = $validator->collection_name;
  $tiny = $validator->tiny;

=cut

sub document         { shift->{document}        }

sub collection_name  { shift->{collection_name} }

sub tiny             { shift->{tiny} }

=head2 has_error

  $validator->has_error && die;

=cut

sub has_error        { @{shift->{errors}} }

=head2 set_error

  $validator->set_error(
      $name => [
  	'error-code','message',
      ]
  );

=cut

sub set_error {
    my $self  = shift;
    validate_pos(
	@_,
	1,
	{ type => ARRAYREF }
    );
    my $field   = shift;
    my $error = shift;
    my ($code,$message) = @{$error};

    my %error = (
	collection => $self->collection_name,
	field      => $field,
	code       => $code    || 'nocode',
	message    => $message || (sprintf "fail: %s",$code)
    );
    push @{$self->{errors}},\%error;
}

=head2 errors

  # erros: [{ field => 'field1', code => 'errorcode', message => 'message1' },,,]
  @erros         = $validator->erros; 
  
  @fields        = $validator->errors('field');
  @error_code    = $validator->errors('code');
  @error_message = $validator->errors('message');

=cut

sub errors {
    my $self = shift;
    my $field  = shift; # list field(field,code,message)
    if ($field) {
	return map { $_->{$field} } @{$self->{errors}};
    }
    return wantarray ? @{$self->{errors}} : $self->{errors};
}

=head2 check

  # no_validate: bool
  # state: [insert,update]
  $validator->check($opt); 

=cut

sub check {
    my $self       = shift;
    my $opt        = shift;

    return $self if $opt->{no_validate};

    my $c_class    = util_document_class($self->collection_name,  ref $self->tiny || $self->tiny );
    my $document   = $self->document;
    my $field      = $c_class->field;

    my $all_fields  = { map { $_ => 1 } $field->list };
    my @fail_fields = grep { ! $all_fields->{$_} } keys %{$document};
    for (@fail_fields) {
        $self->set_error(
            $_ => ['not_field', (sprintf "%s is not field",$_)]
        );
    }

    if ($opt->{state} eq 'insert') {

	for my $name ($field->list('REQUIRED')) {
	    unless (exists $document->{$name}) {
		$self->set_error(
		    $name => [
			'required',(sprintf "%s is required",$name)
		    ]
		);
	    }
	}

	for my $name ($field->list) {
	    unless (exists $document->{$name}) {
		$document->{$name} = undef;
	    }
	}
    }

    for my $name (keys %$document) {
	for my $attr ( @{ $field->get($name) || [] } ) {
	    my $func = $attr->{callback};
	    my ($status,$ret) = $func->($document->{$name}, $self->tiny, $opt);
	    $ret ||= {};
	    validate_with(
		params => $ret,
		spec => {
		    message => 0,
		    target  => 0,
		}
	    );

	    if (!$status) {
		$self->set_error(
		    $name => [$attr->{name},$ret->{message}]
		)
	    } else {
		$document->{$name} = $ret->{target} if defined $ret->{target};
	    }
	}
    }
    $self->{document} = $document;
    return $self;
}

1;
__END__

=head1 AUTHOR

Naoto ISHIKAWA, C<< <toona at seesaa.co.jp> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Naoto ISHIKAWA.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
