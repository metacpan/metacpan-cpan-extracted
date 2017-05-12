#line 1 "inc/Module/Install/Makefile.pm - /usr/local/lib/perl5/site_perl/5.8.0/Module/Install/Makefile.pm"
# $File: //depot/cpan/Module-Install/lib/Module/Install/Makefile.pm $ $Author: autrijus $
# $Revision: #45 $ $Change: 1645 $ $DateTime: 2003/07/16 01:05:06 $ vim: expandtab shiftwidth=4

package Module::Install::Makefile;
use Module::Install::Base; @ISA = qw(Module::Install::Base);

$VERSION = '0.01';

use strict 'vars';
use vars '$VERSION';

use ExtUtils::MakeMaker ();

sub Makefile { $_[0] }

sub prompt { 
    shift;
    goto &ExtUtils::MakeMaker::prompt;
}

sub makemaker_args {
    my $self = shift;
    my $args = ($self->{makemaker_args} ||= {});
    %$args = ( %$args, @_ ) if @_;
    $args;
}

sub clean_files {
    my $self = shift;
    $self->makemaker_args( clean => { FILES => "@_ " } );
}

sub write {
    my $self = shift;
    die "&Makefile->write() takes no arguments\n" if @_;

    my $args = $self->makemaker_args;

    $args->{DISTNAME} = $self->name;
    $args->{NAME} = $self->module_name || $self->name || $self->determine_NAME($args);
    $args->{VERSION} = $self->version || $self->determine_VERSION($args);
    $args->{NAME} =~ s/-/::/g;

    if ($] >= 5.005) {
	$args->{ABSTRACT} = $self->abstract;
	$args->{AUTHOR} = $self->author;
    }
    if ( eval($ExtUtils::MakeMaker::VERSION) >= 6.10 )
    {
        $args->{NO_META} = 1;
    }

    # merge both kinds of requires into prereq_pm
    my $prereq = ($args->{PREREQ_PM} ||= {});
    %$prereq = ( %$prereq, map { @$_ } map { @$_ } grep $_,
                 ($self->build_requires, $self->requires) );

    # merge both kinds of requires into prereq_pm
    my $dir = ($args->{DIR} ||= []);
    push @$dir, map "$self->{prefix}/$self->{bundle}/$_->[1]", @{$self->bundles}
        if $self->bundles;

    my %args = map {($_ => $args->{$_})} grep {defined($args->{$_})} keys %$args;

    if ($self->admin->preop) {
        $args{dist} = $self->admin->preop;
    }

    ExtUtils::MakeMaker::WriteMakefile(%args);

    $self->fix_up_makefile();
}

sub fix_up_makefile {
    my $self = shift;
    my $top_class = ref($self->_top) || '';
    my $top_version = $self->_top->VERSION || '';

    my $preamble = $self->preamble 
       ? "# Preamble by $top_class $top_version\n" . $self->preamble
       : '';
    my $postamble = "# Postamble by $top_class $top_version\n" . 
                    ($self->postamble || '');

    open MAKEFILE, '< Makefile' or die $!;
    my $makefile = do { local $/; <MAKEFILE> };
    close MAKEFILE;

    open MAKEFILE, '> Makefile' or die $!;
    print MAKEFILE "$preamble$makefile$postamble";
    close MAKEFILE;
}

sub preamble {
    my ($self, $text) = @_;
    $self->{preamble} = $text . $self->{preamble} if defined $text;
    $self->{preamble};
}

sub postamble {
    my ($self, $text) = @_;

    $self->{postamble} ||= $self->admin->postamble;
    $self->{postamble} .= $text if defined $text;
    $self->{postamble}
}

1;

__END__

#line 242
