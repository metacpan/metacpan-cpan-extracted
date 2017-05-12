package Module::Install::CPANfile;

use strict;
use 5.008_001;
our $VERSION = '0.12';

use Module::CPANfile;
use base qw(Module::Install::Base);

sub merge_meta_with_cpanfile {
    my $self = shift;

    require CPAN::Meta;

    my $file = Module::CPANfile->load;

    if ($self->is_admin) {
        # force generate META.json
        CPAN::Meta->load_file('META.yml')->save('META.json');

        print "Regenerate META.json and META.yml using cpanfile\n";
        $file->merge_meta('META.yml');
        $file->merge_meta('META.json');
    }

    for my $metafile (grep -e, qw(MYMETA.yml MYMETA.json)) {
        print "Merging cpanfile prereqs to $metafile\n";
        $file->merge_meta($metafile);
    }
}

sub cpanfile {
    my($self, %options) = @_;

    $self->dynamic_config(0) unless $options{dynamic};

    my $write_all = \&::WriteAll;

    *main::WriteAll = sub {
        $write_all->(@_);
        $self->merge_meta_with_cpanfile;
    };

    $self->configure_requires("CPAN::Meta");

    if ($self->is_admin) {
        $self->admin->include_one_dist("Module::CPANfile");
        if (eval { require CPAN::Meta::Check; 1 }) {
            my $prereqs = Module::CPANfile->load->prereqs;
            my @err = CPAN::Meta::Check::verify_dependencies($prereqs, [qw/runtime build test develop/], 'requires');
            for (@err) {
                warn "Warning: $_\n";
            }
        } else {
            warn "CPAN::Meta::Check is not installed. Skipping dependencies check for the author.\n";
        }
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Module::Install::CPANfile - Include cpanfile

=head1 SYNOPSIS

  # cpanfile
  requires 'Plack', 0.9;
  on test => sub {
      requires 'Test::Warn';
  };

  # Makefile.PL
  use inc::Module::Install;
  name 'Dist-Name';
  all_from 'lib/Dist/Name.pm';
  # ...
  cpanfile;
  WriteAll;

=head1 DESCRIPTION

Module::Install::CPANfile is a plugin for Module::Install to include
dependencies from L<cpanfile> into meta files. C<MYMETA> files are
always merged with cpanfile, as well as C<META> files when you run
C<Makefile.PL> as an author mode (as in preparation for C<make dist>).

=head1 WHY?

If you have read L<cpanfile> and L<cpanfile-faq> you might wonder why
this plugin is necessary, since I<cpanfile> is meant to be used by
Perl applications and not distributions.

Well, for a couple reasons.

=head2 Co-exist as a Github project and CPAN distribution

One particular use case is a script or web application that you
develop on github, and you start with writing dependencies in
I<cpanfile>. Other users or developers pull the code from git, use
L<carton> to bundle dependencies. So far, so good.

One day you decide to release the script or application to CPAN as a
CPAN distribtuion, and that means you have to duplicate I<cpanfile>
into I<Makefile.PL> or I<Build.PL>, and that's not DRY! This plugin
will allow you to have just one I<cpanfile> and reuse it from
I<Makefile.PL> for CPAN client use.

=head2 CPAN Meta Spec 2.0 support.

The other, kind of unfortunate reason is that as of this writing,
L<Module::Install> and L<ExtUtils::MakeMaker> don't have a complete
support for expressing L<CPAN::Meta::Spec> version 2.0
vocabularies.

There are many of known issues that the metadata you specify with
L<Module::Install> are somehow discarded or down converted, and
eventually lost in I<MYMETA> files. The examples of those issues are
that test dependencies gets merged with build dependencies, and that
I<recommends> is not saved into MYMETA files.

This plugin lets you write prerequisites in I<cpanfile> which is more
powerful and has a complete support for L<CPAN::Meta::Spec> 2.0 and
makes your application forward compatible.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 COPYRIGHT

Copyright 2012- Tatsuhiko Miyagawa

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<cpanfile> L<Module::CPANfile> L<Module::Install>

=cut
