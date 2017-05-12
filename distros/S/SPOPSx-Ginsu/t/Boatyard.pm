package Boatyard;

use strict;
use vars qw($VERSION @ISA $CONF $TABLE_DEF $HASB_CLASS $HASB_KEY);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.19 $ =~ /: (\d+)\.(\d+)/;
	@ISA = qw/ MyBaseObject /;
	$CONF = {
		BoatyardAlias => {
			class			=> 'Boatyard',
			isa				=> \@ISA,
			field			=> [ qw/ id name / ],
			as_string_order => [ qw/ id class name / ],
			base_table		=> 'Boatyard',
			id_field		=> 'id',
			skip_undef		=> [ qw/ name / ],
			no_security		=> 1,
		},
	};
	$TABLE_DEF = <<SQL;
CREATE TABLE IF NOT EXISTS Boatyard (
	id       int(11) PRIMARY KEY,
	name	char(255)
)
SQL
	$HASB_CLASS = 'Slip';	
	$HASB_KEY = 'list_of_slips';
}

use MyBaseObject;

sub post_save_action {

	my $self = shift;
	my $p = shift;
	$self->SUPER::post_save_action({%$p});
	if  (defined $self->{$HASB_KEY} && ref $self->{$HASB_KEY} eq 'ARRAY'){
		foreach my $slip (@{$self->{$HASB_KEY}}){
			next if (ref $slip ne $HASB_CLASS);
			$slip->{boatyard} = $self->id
				unless defined $slip->{boatyard} && $slip->{boatyard} == $self->id;
			# $p href is not passed because it contains the boatyard fields also.
			die "Cannot save slip $slip->{name}. $!" unless $slip->save()->id;
		}
	}
	return $self;
}

sub post_fetch_action {

	my $self = shift;
	my $p = shift;
	$self->SUPER::post_fetch_action({%$p});		
	$self->{$HASB_KEY} = $HASB_CLASS->fetch_group({ %$p,
							where => $HASB_CLASS->table_name.'.boatyard = ?',
							value => [ $self->id ] });
	return $self;
}

sub pre_remove_action {
	
	my $self = shift;
	my $p = shift;
	$self->SUPER::pre_remove_action({%$p});
	if  (defined $self->{$HASB_KEY} && ref $self->{$HASB_KEY} eq 'ARRAY'){
		foreach my $slip (@{$self->{$HASB_KEY}}){
			next if (ref $slip ne $HASB_CLASS);
			die "Cannot delete slip $slip->{name}. $!" unless $slip->remove({%$p});
		}
	}
	return $self;
}

__PACKAGE__->config_and_init;

1;
