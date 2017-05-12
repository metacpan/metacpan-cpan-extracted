package SMIL::XMLContainer;

$VERSION = "0.898";

use SMIL::XMLBase;

@ISA = qw( SMIL::XMLBase );

my $contents = "_contents";
my $order = "_order";

sub addTagContents {

				my $self = shift;
				my $push = shift;
				my %hash = @_;
				
    my $the_ref = ref( $self );
    
    $self->{$order} = [] unless $self->{$order};
				
    # Build an order array, but make sure we don't reuse items
    my @ordering;
    my $toggle = 0;
				
    foreach $item ( @_ ) {
								if( $toggle = !$toggle ) {

												my $exists = 0;
												
												foreach $pretest_item ( @{$self->{$order}} ) {
																$exists = 1 if $item eq $pretest_item;
												}
												
												if( !$exists ) {
																if( $push ) {
																				push @{$self->{$order}}, $item;
																}
																else {
																				unshift @{$self->{$order}}, $item;
																}
												}
								}
    }
    
    # The contents is a hash 
    my $hash_ref = $self->{$contents};
    if( !$hash_ref ) {
								$hash_ref = {};
    }
				
    # Each item in contents can be a an object (a hash)
    # or an array, so that would likely be an array of hash refs
    foreach $item ( keys %hash ) {
								# See what the item is 
								$type = ref( $hash{ $item } );
								
								if( !$$hash_ref{ $item } ) {
												if( $type =~ /HASH/ ) {
																$$hash_ref{ $item } = [];
												}
												elsif( $type =~ /ARRAY/ ) {
																$$hash_ref{ $item } = [];
												}
								}
								
								# It is setup, now put the item in there
								$hash_ref->{ $item } = $hash{ $item };
    }
				
    $self->{$contents} = $hash_ref;
				
}

sub unshiftTagContents {
				my $self = shift;
				$self->addTagContents( 0, @_ );
}

sub setTagContents {
    my $self = shift;
				$self->addTagContents( 1, @_ );
}

sub getContentObjectNames {
    my $self = shift;
    my $obj_ref = $self->{$contents};
    return keys %$obj_ref;
}

sub getContentObjectByName {
    my $self = shift;
    my $name = shift;

    my $create = shift;
    return $self->{$contents}->{$name};
}

sub getAsString {
    my $self = shift;
    my $return_string;
    my $tab = $self->getTabBuffer();
  
    $return_string .= 
								"$tab<" . $self->getTag() . $self->_build_attributes() . ">\n";
    $self->increaseTabBuffer();
				
    my $contents_ref = $self->{$contents};
    my $order_ref = $self->{$order};
    foreach $item ( @$order_ref ) {
								
								my $obj = $$contents_ref{ $item };
								my $type = ref $obj;
								
								if( $type =~ /ARRAY/ ) {
												foreach $nibble ( @$obj ) {
																$return_string .= $nibble->getAsString() . "\n" if $nibble;
												}
								}
								else {
												$return_string .= $obj->getAsString() . "\n" if $obj;
												
								}
    }

    $self->decreaseTabBuffer();
    $return_string .= "$tab</" . $self->getTag() . ">";
    
    return $return_string;
}

