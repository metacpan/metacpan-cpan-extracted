package Rhetoric::Theme::SandStone;
use strict;
use warnings;
our $VERSION = '0.08';
use Squatting::View;
use Method::Signatures::Simple;

our $view = Squatting::View->new(

  'SandStone',

  _init => method($include_path) {
    $self->{tt} = Template->new({
      INCLUDE_PATH => $include_path,
      POST_CHOMP   => 1,
    });
  },
  layout => method($v, $content) {
    my $output;
    $v->{R}       = \&Rhetoric::Views::R;
    $v->{content} = $content;
    $self->{tt}->process('layout.html', $v, \$output);
    $output;
  },
  _ => method($v) {
    my $file = "$self->{template}.html";
    my $output;
    $v->{R} = \&Rhetoric::Views::R;
    my $r   = $self->{tt}->process($file, $v, \$output);
    warn $r unless ($r);
    $output;
  },
);

sub view { $view }

1;
__END__

=head1 NAME

Rhetoric::Theme::SandStone - a dark theme for Rhetoric blogs

=head1 SYNOPSIS

  use Rhetoric::Theme::SandStone;

=head1 DESCRIPTION

Rhetoric::Theme::SandStone is based on the SandStone theme from Free CSS Templates.

=head1 SEE ALSO

L<http://www.freecsstemplates.org/preview/sandstone/>

=head1 AUTHOR

John BEPPU E<lt>beppu {at} cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
