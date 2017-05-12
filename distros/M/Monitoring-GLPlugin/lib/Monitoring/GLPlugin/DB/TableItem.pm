package Monitoring::GLPlugin::DB::TableItem;
our @ISA = qw(Monitoring::GLPlugin::DB::CSF Monitoring::GLPlugin::TableItem Monitoring::GLPlugin::DB);
use strict;

sub globalize_errors {
  my ($self) = @_;
  #delete *{'add_message'};
  {
    no strict 'refs';
    foreach my $sub (qw(add_ok add_warning add_critical add_unknown
        add_message check_messages)) {
      *{$sub} = *{'Monitoring::GLPlugin::'.$sub};
    }
  }
}

sub localize_errors {
  my ($self) = @_;
  $self->{messages} = { 
      ok=> [],
      warning => [],
      critical => [],
      unknown => []
  } if ! exists $self->{messages};
  # save global errors
  {
    no strict 'refs';
    foreach my $sub (qw(add_ok add_warning add_critical add_unknown
        add_message check_messages)) {
      *{$sub} = *{'Monitoring::GLPlugin::Commandline::'.$sub};
    }
  }
}

1;

__END__
