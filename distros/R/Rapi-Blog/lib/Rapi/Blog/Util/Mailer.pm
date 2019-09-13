package Rapi::Blog::Util::Mailer;
use strict;
use warnings;

# ABSTRACT: General mailer object with defaults

use Moo;
use Types::Standard qw(:all);

use RapidApp::Util qw(:all);

require Module::Runtime;
use Email::Sender::Transport;
use Email::Sender::Transport::Sendmail;
use Email::Sender::Transport::SMTP;
use Email::Sender::Simple;
use Email::Simple;
use Email::Abstract;
use Path::Class qw/file dir/;


has 'smtp_config', is => 'ro', isa => Maybe[HashRef], default => sub { undef };

sub send {
  my $self = shift;
  
  my %args = (scalar(@_) == 1) && (blessed($_[0]) || !ref($_[0]))
    ? ( message => $_[0] )
    : (ref($_[0]) eq 'HASH') ? %{ $_[0] } : @_; # <-- arg as hash or hashref
  
  
  # If we're called as a class method:
  return $self->new(\%args)->send unless (blessed $self);
  
  # We're an already created object, we shouldn't see any arguments:
  die "->send() only accepts arguments when called as a class method" if (scalar(keys %args) > 0);

  $self->_send
}


sub _send {
  my $self = shift;
  
  $self->sent and die "Already sent.";
  
  $self->envelope_to or die "Unable to send message - no recipient addresses were supplied or identified.";
  
  Email::Sender::Simple->send($self->email, { 
    to        => $self->envelope_to,
    from      => $self->envelope_from,
    transport => $self->transport
  });
  
  $self->sent(1);
}




sub BUILD {
  my $self = shift;
  
  # Perform initializations:
  $self->init;
}

sub init {
  my $self = shift;
  
  # Perform initializations:
  $self->transport;
  $self->email;
  
  $self->initialized or die "Unknown error; not initialized";
  
  $self
}


has 'message_file', is => 'ro', lazy => 1, default => sub { undef },
isa => Maybe[InstanceOf['Path::Class::File']], coerce => sub {
  return undef unless ($_[0]);
  my $File = file($_[0]);
  -f $File or die "message_file '$_[0]' not found or is not a regular file";
  $File
},



has 'transport', 
  is      => 'ro', 
  isa     => ConsumerOf['Email::Sender::Transport'],
  lazy    => 1,
  default => sub {
    my $self = shift;
    
    # If there is no custom smtp_config, we use the default Sendmail transport
    # which relies of the sendmail binary to send mail from the localhost
    return Email::Sender::Transport::Sendmail->new unless ($self->smtp_config);
    
    my $cfg = clone($self->smtp_config);
    
    # If there is a custom config, look for the special 'transport_class' option
    # to override the default Email::Sender::Transport::SMTP. The rest of the 
    # params are passed directly to the transport constructor ->new()
    my $class = $cfg->{transport_class} 
      ? delete $cfg->{transport_class}
      : 'Email::Sender::Transport::SMTP';
      
    $class->new($cfg)
  };
  

has 'message', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  return scalar($self->message_file->slurp) if $self->message_file
}, isa => Maybe[Str];

has 'body', is => 'ro', isa => Str, lazy => 1, default => sub {
  my $self = shift;
  $self->email->body || $self->default_body
};


#has 'default_to',      is => 'ro', isa => Str, default => sub { 'unspecified-address@unspecified-domain.com' };
#has 'default_from',    is => 'ro', isa => Str, default => sub { 'unspecified-address@unspecified-domain.com' };

has 'default_to', is => 'ro', default => sub { undef }, isa => Maybe[ArrayRef[Str]], coerce => \&_array_coerce;


has 'default_from',    is => 'ro', isa => Str, default => sub { '"Rapi::Blog administrator" <no-reply@rapid.app>' }; 
has 'default_subject', is => 'ro', isa => Str, default => sub { '(no subject)' }; 
has 'default_body',    is => 'ro', isa => Str, default => sub { '' }; 

has 'default_headers', is => 'ro', default => sub {[
  'X-Mailer-Class' => __PACKAGE__
]}, isa => ArrayRef;



has 'envelope_from', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->init;
  ($self->_extract_addresses($self->from))[0]
}, isa => Str;

has 'envelope_to', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->init->identified_recipients;
}, isa => Maybe[ArrayRef[Str]], coerce => \&_array_coerce;


has 'from', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->init->exist_header->{from} || $self->default_from
}, isa => ArrayRef[Str], coerce => \&_array_coerce;


has 'to', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->init->exist_header->{to} || $self->default_to
}, isa => ArrayRef[Str], coerce => \&_array_coerce;


has 'cc', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
   $self->init->exist_header->{cc} || undef
}, isa => Maybe[ArrayRef[Str]], coerce => \&_array_coerce;

has 'bcc', is => 'ro', lazy => 1, default => sub { undef }, isa => Maybe[ArrayRef[Str]], coerce => \&_array_coerce;

has 'subject', is => 'ro', lazy => 1, default => sub {
  my $self = shift;
  $self->init;
  $self->exist_header->{subject} || $self->defult_subject
}, isa => Str;

has 'importance', is => 'ro', isa => Maybe[Enum[qw/Low Normal High/]], 
  default => sub { undef }, coerce => sub { $_[0] ? ucfirst(lc($_[0])) : undef };



sub _array_coerce {
  my $val = shift or return undef;
  $val = [$val] unless (ref($val)||'' eq 'ARRAY');
  scalar(@$val) > 0 ? $val : undef
}

has 'initialized',           is => 'rw', isa => Bool,          default => sub {0};
has 'sent',                  is => 'rw', isa => Bool,          default => sub {0};
has 'exist_header',          is => 'ro', isa => HashRef,       default => sub {{}};
has 'identified_recipients', is => 'ro', isa => ArrayRef[Str], default => sub {[]};

has 'email', is => 'ro', init_arg => undef, lazy => 1, default => sub {
  my $self = shift;
  $self->initialized(0);
  
  my @addr_collect = ();
  
  my $email = Email::Abstract->new( $self->message
    ? $self->message
    : Email::Simple->create( header => $self->default_headers )
  ) or die "unknown error occured parsing message";
  
  my @recip_headers = qw/to cc bcc/; my %recip = map {$_=>1} @recip_headers; 
  my @headers = (@recip_headers,qw/from subject/);
  for my $header (@headers) {
    my $normal = ucfirst(lc($header));
    if($self->meta->get_attribute($header)->has_value($self)) {
      my $value = $self->$header;
      if(ref($value)||'' eq 'ARRAY') { # By rule, all attr headers which are ArrayRefs are addresses
        $recip{$header} and push @addr_collect, @$value;
        $value = join(', ',@$value);
      }
      $email->set_header( $normal => $value ) unless ($header eq 'bcc');
    }
    else {
      if(my $value = $email->get_header($normal)) {
        $recip{$header} and push @addr_collect, $value;
        $self->exist_header->{$header} = $value;
      }
    }
  }
  
  if (my $importance = $self->importance) {
    $email->set_header( Importance => $self->importance );
    $email->set_header( 'X-Priority' => 
      $self->importance eq 'High'   ? 1 : 
      $self->importance eq 'Normal' ? 3 : 
      $self->importance eq 'Low'    ? 5 : undef 
    );
  }
  
  
  
  # Finally set additional default headers which haven't already been set:
  my %headers = @{$self->default_headers};
  $email->get_header($_) or $email->set_header( $headers{$_} ) for (keys %headers);
  
  # Do the same for body: user-supplied value first, then auto parsed value, then default as last resort
  $self->meta->get_attribute('body')->has_value($self) and $email->set_body( $self->body );
  $email->get_body or $email->set_body( $self->body );
  
  push @addr_collect, $self->default_to if (scalar(@addr_collect) == 0 && $self->default_to);
  
  @{$self->identified_recipients} = map { $self->_extract_addresses($_) } @addr_collect;

  $self->initialized(1);
  
  return $email
  
}, isa => InstanceOf['Email::Abstract'];



sub _extract_addresses {
  my ($self, @vals) = @_;
  
  my @addrs = ();
  for my $val (@vals) {
    if (ref($val)||'' eq 'ARRAY') {
      push @addrs, $self->_extract_addresses(@$val);
    }
    else {
      for my $EA (grep {$_} Email::Address->parse($val)) {
        my $addr = $EA->address or next;
        push @addrs, $EA->address;
      }
    }
  }
  uniq(@addrs)
}



1;


__END__

=head1 NAME

Rapi::Blog::Util::Mailer - General mailer object with defaults


=head1 DESCRIPTION

Sends E-Mails

=head1 SEE ALSO

=over

=item * 

L<rabl.pl>

=back

=head1 AUTHOR

Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
