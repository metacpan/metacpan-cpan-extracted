#line 1
package Module::Install::Template;

use strict;
use warnings;
use Cwd;
use File::Temp 'tempfile';
use Data::Dumper;


our $VERSION = '0.06';


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
        @other_authors = ref $args{other_authors} eq 'ARRAY'
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

#line 261

