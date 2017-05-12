package Module::Install::Template;
use 5.006;
use strict;
use warnings;
use Cwd;
use File::Temp 'tempfile';
use Data::Dumper;
our $VERSION = '0.08';
use base qw(Module::Install::Base);

sub is_author {
    my $author = $^O eq 'VMS' ? './inc/_author' : './inc/.author';
    -d $author;
}

sub tag {
    my $self = shift;
    (my $name = lc $self->name) =~ s/-//g;
    $name;
}

sub rt_email {
    my $self = shift;
    sprintf '<bug-%s@rt.cpan.org>', lc $self->name;
}

sub year_str {
    my ($self, $first_year) = @_;
    my $this_year = ((localtime)[5] + 1900);
    return $this_year if (!defined $first_year) || $first_year == $this_year;
    die "first year ($first_year) is after this year ($this_year)?\n"
      if $first_year > $this_year;
    return "$first_year-$this_year";
}

sub process_templates {
    my ($self, %args) = @_;

    # only module authors should process templates; if you're not the original
    # author, you won't have the templates anyway, only the generated files.
    return unless $self->is_author;
    $::WANTS_MODULE_INSTALL_TEMPLATE = 1;
    my @other_authors;
    if (defined $args{other_authors}) {
        @other_authors =
          ref $args{other_authors} eq 'ARRAY'
          ? @{ $args{other_authors} }
          : ($args{other_authors});
    }
    my $config = {
        template => {
            INCLUDE_PATH => "$ENV{HOME}/.mitlib",
            (defined $args{start_tag} ? (START_TAG => $args{start_tag}) : ()),
            (defined $args{end_tag}   ? (END_TAG   => $args{end_tag})   : ()),
        },
        vars => {
            name     => $self->name,
            year     => $self->year_str($args{first_year}),
            tag      => $self->tag,
            rt_email => $self->rt_email,
            base_dir => getcwd(),
            (@other_authors ? (other_authors => \@other_authors) : ()),
        },
    };
    my ($fh, $filename) = tempfile();
    print $fh Data::Dumper->Dump([$config], ['config']);
    close $fh or die "can't close $filename: $!\n";
    $self->makemaker_args(PM_FILTER => "tt_pm_to_blib $filename");

    # Some of the following may not have been available in the template; the
    # module author can specify that they should come from somewhere else.
    if (defined $args{rest_from}) {

        # try to get all values that haven't been defined yet from the
        # indicated source
        for my $key (qw(version perl_version author license abstract)) {
            next if defined($self->$key) && length($self->$key);
            my $method = "${key}_from";
            $self->$method($args{rest_from});
        }
    }
    $self->all_from($args{all_from})
      if defined $args{all_from};
    $self->version_from($args{version_from})
      if defined $args{version_from};
    $self->perl_version_from($args{perl_version_from})
      if defined $args{perl_version_from};
    $self->author_from($args{author_from})
      if defined $args{author_from};
    $self->license_from($args{license_from})
      if defined $args{license_from};
    $self->abstract_from($args{abstract_from})
      if defined $args{abstract_from};
}

# 'make dist' uses ExtUtils::Manifest's maniread() and manicopy() to determine
# what should be copied into the dist dir. This is fine for most purposes, but
# with Moduile::Install::Template we really want the finished files, not the
# templates. So we override the create_distdir rule here, but only if we're
# the author - the end user shouldn't be bothered with any of this
# kludge^Wmagic.
#
# We still use maniread() to get the file names, but then change those
# filenames pointing into lib/ to point into blib/lib instead. Now the right
# files get copied, but they end up in the wrong place - in the dist dir's
# blib/lib/. So at the end we move them to the right place and delete the dist
# dir's blib/ directory.
#
# And 'make disttest' needs to be modified as well; we need to have the blib/
# files before we can test the distribution. So I've added a 'pm_to_blib'
# requirement to the 'disttest' target.
sub MY::postamble {
    my $self = shift;
    no warnings 'once';
    return '' if defined $::IS_MODULE_INSTALL_TEMPLATE;

    # for some reason, Module::Install runs this subroutine even if the
    # Makefile.PL doesn't specify process_template(). So here we check whether
    # process_template() has been run.
    return '' unless defined $::WANTS_MODULE_INSTALL_TEMPLATE;
    return '' unless Module::Install::Template->is_author;
    return <<'EOPOSTAMBLE';
create_distdir : pm_to_blib
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
	    -e '$$m = maniread(); while (($$k, $$v) = each %$$m) { next if $$k !~ m!^lib/!; delete $$m->{$$k}; $$m->{"blib/$$k"} = $$v; }; manicopy($$m, "$(DISTVNAME)", "$(DIST_CP)"); '
	$(MV) $(DISTVNAME)/blib/lib $(DISTVNAME)/lib
	$(RM_RF) $(DISTVNAME)/blib

disttest : pm_to_blib distdir
	cd $(DISTVNAME) && $(ABSPERLRUN) Makefile.PL 
	cd $(DISTVNAME) && $(MAKE) $(PASTHRU)
	cd $(DISTVNAME) && $(MAKE) test $(PASTHRU)
EOPOSTAMBLE
}
1;
__END__

=head1 NAME

Module::Install::Template - Treat module source code as a template

=head1 SYNOPSIS

    # in C<Makefile.PL>:

    process_templates(
        first_year => 2007,
        rest_from  => "$ENV{HOME}/.mitlib/standard_pod",
        start_tag  => '{%',
        end_tag    => '%}',
    );

=head1 DESCRIPTION

This module, if used in the C<Makefile.PL> as shown in the synopsis, treats
module source code files as templates and processes them with the L<Template>
Toolkit during C<make> time.

That is, C<lib/> is expected to contain templates, and C<blib/lib/> will
contain the resulting files as processed by the Template Toolkit.

This only happens on the author's side. The end-user will not notice any of
it.

This module provides one subroutine: C<process_templates()>. It takes named
arguments. Of these, C<start_tag> and C<end_tag> are treated specially and
used for the template's start and end tag definitions. C<rest_from> instructs
this module to look for distribution attributes (C<version>, C<perl_version>,
C<author>, C<license>, C<abstract>) that haven't been set yet in the given
file.

For example, you might have some standard POD template that you use in all
your modules - standard stuff like installation, availability, author,
copyright notices and so on. You could have that in the special directory
C<~/.mitlib> (C<mit> here stands for 'Module::Install::Template'). Because
of that, the Module::Install directive C<all_from> won't work properly.
With C<rest_from> you can instruct this module to take the remaining
distribution attributes from your standard template.

The Makefile had to be slightly patched so that C<make dist> still works -
normally C<make dist> takes files from C<lib/>, but here these are the
templates. We are interested in the finished files, so we override the
relevant Makefile portions to use C<blib/lib/> instead.

This documentation is somewhat lacking - I'll try to improve it.

Because of the C<Makefile> munging, this module might not work for
distributions that use XS or SWIG.

=head1 TAGS

If you talk about this module in blogs, on L<delicious.com> or anywhere else,
please use the C<moduleinstalltemplate> tag.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-module-install-template@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see L<http://search.cpan.org/dist/Module-Install-Template/>.

=head1 AUTHOR

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

