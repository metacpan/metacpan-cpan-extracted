package Number::MuPhone::Parser::US;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'                    => ( default => 'US'            );
has '+country_code'               => ( default => '1'             );
has '+country_name'               => ( default => 'United States' );
has '+_national_dial_prefix'      => ( default => '1'             );
has '+_international_dial_prefix' => ( default => '011'           );

# although there's a national dial code, it's not usually displayed
has '+_national_display' => (
  default => sub {
    my $self = shift;
    my $num = $self->_cleaned_number;
    $num =~ s/(\d{3})(\d{3})(\d{4})/($1) $2-$3/;
    $num .= $self->_extension_display;
    return $num;
  }
);

sub _format_number {
  my $self = shift;
  my $num = $self->_cleaned_number;
  
  # all US numbers have same format, which is nice
  # XXX XXX XXXX
     $num =~ s/^(\d{3})(\d{3})(\d{4})$/$1 $2 $3/
  or $self->error("Invalid US phone number");

  return $num; 
}

1;
