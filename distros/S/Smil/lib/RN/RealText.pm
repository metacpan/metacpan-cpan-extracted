package RN::RealText;

$VERSION = "0.898";

sub new {
				my $proto = shift;
				my $class = ref( $proto ) || $proto;
				my $self = {};
				
				my %atts = @_;
				my $item;

				# Fill in the attributes
				foreach $item ( keys %atts ) {
								$self->{$item} = $atts{ $item };
				}

				# Set window type if not set above
				$self->{type} = 'generic' unless $self->{type};

				$self->{_code} = ();
				
				bless( $self, $class );
				return $self;
}

sub getMimeType {
				my $self = shift;
				my $return_string = 'text/vnd.rn-realtext';
				return $return_string;
}

sub getAsString {
				my $self = shift;
				my $return_string = "";

				$return_string .= "<window";

				foreach my $item ( keys %{$self} ) {
								if( $item ne "_code" ) {
												$return_string .= " $item=\"" . $self->{$item} . "\"";
								}
				}
				$return_string .= ">\n";

				# Now, do the code
				$return_string .= ( join "", @{$self->{_code}} );

				$return_string .= "</window>";

				return $return_string;
}

sub addCode {
				my $self = shift;
				my $code = shift;
				
				push @{$self->{_code}}, $code;
}

sub addText {
				addCode( @_ );
}

1;

