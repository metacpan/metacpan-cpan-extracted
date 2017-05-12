package Module::Checkstyle;

use warnings;
use strict;
use Carp;

use PPI;
use File::HomeDir qw(home);
use File::Spec::Functions qw(catfile rel2abs);
use File::Find::Rule;
use List::Util qw(first);
use Module::Pluggable search_path => [qw(Module::Checkstyle::Check)], require => 1;

use Module::Checkstyle::Config;
use Module::Checkstyle::Util qw(:problem);

our $VERSION = "0.04";

# Controls if we want to be more verbose
our $debug = 0;

sub new {
    my ($class, $config) = @_;
    
    # Standard remake ref to name for pre 5.8 Perls
    $class = ref $class || $class;
    
    # Load config from ~/.module-checkstyle/config or supplied file
    $config = Module::Checkstyle::Config->new($config);

    if ($debug) {
        if ($config->get_directive('_', '_config-path')) {
            print STDERR "Using configuration from: ", $config->get_directive('_', '_config-path'), "\n";
        }
    }
    
    my $self = bless {
                      config   => $config,
                      checked  => {},
                      problems => [],
                      handlers => {},
                  }, $class;
    
    # Config file determines what checks to enable by declaring them as 
    my %enable_plugin = map { $_ => 1 } $config->get_enabled_sections();
    my @plugins = Module::Checkstyle->plugins;
    foreach my $plugin_class (@plugins) {
        my $name = $plugin_class;
        $name =~ s/^Module::Checkstyle::Check:://;
        if ($enable_plugin{$name}) {
            my %event = $plugin_class->register();
            if (%event) {
                my $plugin = $plugin_class->new($config);
                while (my ($event, $handler) = each %event) {
                    push @{$self->{handlers}->{$event}}, [$plugin, $handler];
                }
            }
        }
    }
    
    return $self;
}

sub _check_file {
    my ($self, $file) = @_;
    
    # Check for perl in shebang
    if ($file !~ /\.(?:pm|pl)$/i) {
        my $skip = 0;
        eval {
            open my $fh, "<", $file || die $!;
            my $shebang = <$fh>;

            if (defined $shebang) {
                chomp $shebang;
                $skip = 1 if $shebang !~ /^\#\!.*perl/;
            }
            else {
                $skip = 1;
            }
          
            close($fh);
        };
        return if $skip;
        
        if ($@) {
            push @{$self->{problems}}, make_problem('error',
                                                    $@,
                                                    undef,
                                                    $file);
            return;
        }
    }
    
    my $document = PPI::Document->new($file);
    
    if (!$document) {
        push @{$self->{problems}},  make_problem('error',
                                                 PPI::Document->errstr,
                                                 undef,
                                                 $file);
        return;
    }
  
    # Do all the checking
    $document->index_locations();
    $self->_traverse_element($document, $file);
    
    1;
}

# The following who declarations (@exlude) and (@include) are copied from AnnoCPAN
# by Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

# default files to ignore
my @excludes = (
               qr(/inc/),      # used by Module::Install bundles
               qr(/t/),
               qr(/eg/),
               qr(/blib/),
               qr(/pm_to_blib),
               qr(/?Makefile(.PL)?$),
               qr(/Build.PL$),
               qr(/MANIFEST$)i,
               qr(/README$)i,
               qr(/Changes$)i,
               qr(/ChangeLog$)i,
               qr(/LICENSE$)i,
               qr(/TODO$)i,
               qr(/AUTHORS?$)i,
               qr(/CVS/\w+$),
               qr(/.svn/),
               qr(~$), # backup files
               qr(/\#.*\#$), # backup files
              );

# default files to include
my @includes = (
               qr{.(pm|pl)$}i,
               qr{/[^./]+$},       # files with no extension (typically scripts)
              );

sub _any_match {
    my ($value, $list) = @_;
    
    if (first { $value =~ $_ } @$list) {
        return 1;
    }
    
    return 0;
}

sub _get_files {
    my ($dir, $ignore_common) = @_;
    
    my @files = File::Find::Rule->file()->ascii()->in($dir);
    
    @files = map { rel2abs($_) } @files;
    
    if ($ignore_common) {
        @files = grep { _any_match($_, \@includes) && $_ } @files;
        @files = grep { !_any_match($_, \@excludes) && $_ } @files;
    }
    
    return @files;
}

sub check {
    my $self = shift;
    my $args = ref $_[-1] eq 'HASH' ? pop : { ignore_common => 1 };
    
    my @check_files;

  GET_FILES:
    foreach my $file (@_) {
        next GET_FILES if !defined $file;
        
        if (!-e $file) {
            croak "$file does not exist";
        }
        
        if (-d $file) {
            # Passing ignore_common => 1 or ommiting it turns on ignoration
            # of common files usually found in distributions such as README,
            # blib/*, inc/*, t/*
            push @check_files, _get_files($file, $args->{ignore_common});
        }
        else {
            push @check_files, $file;
        }
    }
    
    foreach my $file (@check_files) {
        $self->_check_file($file);
    }
    
    return scalar @{$self->{problems}};
}

sub _post_event {
    my ($self, $event, @args) = @_;
    
    if (exists $self->{handlers}->{$event}) {
        my @handlers = @{$self->{handlers}->{$event}};
        if (@handlers) {
            foreach my $handler (@handlers) {
                my ($object, $callback) = @$handler;
                eval {
                    my @problems = $callback->($object, @args);
                    push @{$self->{problems}}, @problems;
                };
                if ($@) {
                    croak $@;
                }
            }
        }
    }
}

sub _traverse_element {
    my ($self, $element, $file) = @_;
    
    my $event = ref $element;
    my $post_leave = 0;
    if ($element->isa('PPI::Node')) {
        $self->_post_event("enter $event", $element, $file);
        $post_leave = 1;
    }
    
    $self->_post_event($event, $element, $file);
    
    if ($element->isa('PPI::Node')) {
        foreach my $child ($element->children) {
            $self->_traverse_element($child, $file);
        }
    }
    
    if ($post_leave) {
        $self->_post_event("leave $event", $element, $file);
    }
}

sub flush_problems {
    my ($self) = @_;
    my $problems = $self->{problems};
    $self->{problems} = [];
    return wantarray ? @$problems : $problems;
}

sub get_problems {
    my ($self) = @_;
    return wantarray ? @{$self->{problems}} : $self->{problems};
}

1;
__END__

=head1 NAME

Module::Checkstyle - Validate that your code confirms to coding guidelines

=head1 SYNOPSIS

    use Module::Checkstyle;

    my $checkstyle = Module::Checkstyle->new();
    $checkstyle->check("/path/to/my_script.pl");
    foreach my $problem ($checkstyle->get_problems) {
        print $problem, "\n";
    }

=head1 DESCRIPTION

Module::Checkstyle is a tool similar to checkstyle L<http://checkstyle.sourceforge.net> for Java.
It allows you to validate that your code confirms to a set of guidelines checking various things
such as indentation, naming, whitespace, complexity and so forth.

Module::Checkstyle is also extensible so your organization can implement custom checks that
are not provided by the standard distribution. There is a guide on how to write checks
in L<Module::Checkstyle::Check>

=head1 USAGE

Module::Checkstyle is mostly used via the provided C<module-checkstyle> tool. You probablly want to
read L<module-checkstyle>.

=head1 METHODS

=over 4

=item new (I<$config>)

Creates a C<Module::Checkstyle> object. The optional argument I<$config> is passed directly to
the constructor of C<Module::Checkstyle::Config>. If ommited it will load the configuration from
I<~/.module-checkstyle/config> if it exists.

=item check(@paths I<, $args>);

Checks all paths given in I<@files>. If a path is a directory it is reqursively searched for
"parsable" files which will be checked.

The optional argument I<$args> must be a HASH reference and may contain
the following options:

=over 4

=item ignore_common

If ignore_common is set to a false value the C<check> method will B<not> ignore
what it considers to be common files such as MANIFEST, inc/*, blib/*, Makefile.PL, Build.PL etc.
If it is ommited or set to a true value common files will be ignored.

=back

This method returns a true value if there are any violations reported in the C<Module::Checkstyle> object
it is invoked on. To flush the problem list call C<flush_problems> first.

=item flush_problems

Flushes the list of problems. In list context it returns the current a list of
C<Module::Checkstyle::Problem> objects. In scalar context it returns a reference to the list.

=item get_problems

In list context it returns a list of C<Module::Checkstyle::Problem> objects that has
been found by the checker since last flush. In scalar context it returns a reference to the
list.

=back

=head1 CONTRIBUTING

This project is work in progress which means it can always be improved. If you are interested in
contributing tests, bug-fixes, new checks or other please contact me via email (the address is below).
I get a lot of email so don't be suprised if you don't get an answer right away.

If you're sending me a patch please submit it in unified diff format (diff -u) complete with test-cases via
L<http://rt.cpan.org/>

If you want to write a check module you think should be included in this distribution it can either can be
mailed directly to me (the address is below) or posted via L<http://rt.perl.org>. Mark the bug as I<wishlist> or
I<(empty)>.

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to
C<bug-module-checkstyle@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 THANKS

Special thanks goes to Adam Kennedy (ADAMK) for creating PPI which is what made
this all possible in the first place.

=head1 AUTHOR

Claes Jacobsson  C<< <claesjac@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Claes Jacobsson C<< <claesjac@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
