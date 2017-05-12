package Module::New::Command::Version;

use strict;
use warnings;
use Carp;
use Module::New::Meta;
use Module::New::Queue;
use Path::Tiny;
use version;
use Version::Next;

functions {

  update_versions => sub () { Module::New::Queue->register(sub {
    my ($self, $version) = @_;
    my $context = Module::New->context;
    my $root = $context->path->_root;

    require Parse::LocalDistribution;
    my $parser = Parse::LocalDistribution->new({ALLOW_DEV_VERSION => 1});
    my $info = $parser->parse($root);
    my @versions = map {$_->[1]}
                   sort {$b->[0] <=> $a->[0]}
                   map {[version->parse($info->{$_}{version}), $info->{$_}{version}]}
                   grep {defined $info->{$_}{version}}
                   keys %$info;
    $version ||= Version::Next::next_version($versions[0]);
    croak "version $version is equal to or older than $versions[0]" if version->parse($version) <= version->parse($versions[0]);

    for my $package (keys %$info) {
      my $old_version = $info->{$package}{version};
      next unless defined $old_version && $old_version ne 'undef';
      my $file = $info->{$package}{infile} or next;
      my $content = path($file)->slurp;
      $content =~ s|(VERSION\s*=\s*["'])$old_version(["'])|$1$version$2|;
      path($file)->spew($content);
      $context->log( info => "updated $file" );
    }

    $context->log( info => "updated VERSION(s) to $version" );
  })},
};

1;

__END__

=encoding utf-8

=head1 NAME

Module::New::Command::Version

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kenichi Ishigaki.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
