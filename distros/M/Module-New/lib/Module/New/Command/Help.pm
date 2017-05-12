package Module::New::Command::Help;

use strict;
use warnings;
use Carp;
use Module::New::Meta;
use Module::New::Queue;
use Path::Tiny;
use String::CamelCase 'decamelize';

functions {
  help => sub () { Module::New::Queue->register(sub {
    my ($self, $target) = @_;

    my $context = Module::New->context;

    my %descriptions;
    my $max_length = 0;
    foreach my $inc ( @INC ) {
      foreach my $base ( $context->loader->_base ) {
        $base .= '::Recipe';
        (my $path = $base) =~ s|::|/|g;
        my $dir = path($inc, $path);
        next unless $dir->exists;
        foreach my $recipe ( $dir->children ) {
          my $basename = $recipe->basename;
             $basename =~ s/\.pm$//;
          my $package  = "$base\::$basename";
          my $command  = decamelize($basename);

          if ( $target ) {
            next if $command ne $target;

            require Pod::Simple::Text;
            Pod::Simple::Text->filter("$recipe");
            return;
          }

          my $source = $recipe->slurp;
          my ($description) = $source =~ /=head1 NAME\s+$package\s+\-\s+(.+?)\s+=head1/s;
             $description ||= '<no description>';
          $descriptions{$command} ||= $description;
          my $length = length $command;
          $max_length = $length if $max_length < $length;
        }
      }
    }

    foreach my $command (sort keys %descriptions) {
      my $padding = ' ' x ($max_length - (length $command));
      print "  $command$padding - $descriptions{$command}\n";
    }

  })}
};

1;

__END__

=head1 NAME

Module::New::Command::Help

=head1 FUNCTIONS

=head2 help

shows command list or a specific pod.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
