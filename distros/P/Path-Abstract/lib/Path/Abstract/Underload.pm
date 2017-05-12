package Path::Abstract::Underload;
BEGIN {
  $Path::Abstract::Underload::VERSION = '0.096';
}
# ABSTRACT: Path::Abstract without stringification overloading

use warnings;
use strict;


use Sub::Exporter -setup => {
	exports => [ path => sub { sub {
		return __PACKAGE__->new(@_)
	} } ],
};
use Scalar::Util qw/blessed/;
use Carp;

require Path::Abstract::Fast; # For now...


sub new {
	my $path = "";
	my $self = bless \$path, shift;
	$self->set(@_);
	return $self;
}

sub clone {
	my $self = shift;
	my $path = $$self;
	return bless \$path, ref $self;
}

sub _canonize(@) {
	no warnings 'uninitialized';
    @_ = map {
        $_ = ref && (ref eq "Path::Abstract::Underload" || blessed $_ && $_->isa("Path::Abstract::Underload")) ? $$_ : $_;
        length() ? $_ : ();
    } map {
        ref eq "ARRAY" ? @$_ : $_
    } @_;
	my $leading = $_[0] && substr($_[0], 0, 1) eq '/';
	my $path = join '/', @_;
    my $trailing = $path && substr($path, -1) eq '/';

	# From File::Spec::Unix::canonpath
	$path =~ s|/{2,}|/|g;				# xx////xx  -> xx/xx
	$path =~ s{(?:/\.)+(?:/|\z)}{/}g;		# xx/././xx -> xx/xx
	$path =~ s|^(?:\./)+||s unless $path eq "./";	# ./xx      -> xx
	$path =~ s|^/(?:\.\./)+|/|;			# /../../xx -> xx
	$path =~ s|^/\.\.$|/|;				# /..       -> /
	$path =~ s|/\z|| unless $path eq "/";		# xx/       -> xx
	$path .= '/' if $path ne "/" && $trailing;

	$path =~ s/^\/+// unless $leading;
	return $path;
}

sub set {
	my $self = shift;
	$$self = _canonize @_;
	return $self;
}

sub is_empty {
	my $self = shift;
	return $$self eq "";
}
for (qw(is_nil)) { no strict 'refs'; *$_ = \&is_empty }

sub is_root {
	my $self = shift;
	return $$self eq "/";
}

sub is_tree {
	my $self = shift;
	return substr($$self, 0, 1) eq "/";
}

sub is_branch {
	my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
#    return $$self && substr($$self, 0, 1) ne "/";
    return ! $$self || substr($$self, 0, 1) ne "/";
}

sub to_tree {
	my $self = shift;
	$$self = "/$$self" unless $self->is_tree;
	return $self;
}

sub to_branch {
	my $self = shift;
	$$self =~ s/^\///;
	return $self;
}

sub list {
	my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
    return grep { length $_ } split m/\//, $$self;
}
for (qw()) { no strict 'refs'; *$_ = \&list }

sub split {
    my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
    my @split = split m/(?<=.)\/(?=.)/, $$self;
    return @split;
}

sub first {
	my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
    return $self->at(0);
}

sub last {
	my $self = shift;
    Path::Abstract->_0_093_warn if $Path::Abstract::_0_093_warn;
    return $self->at(-1);
}

sub at {
    my $self = shift;
    return '' if $self->is_empty;
    my @path = split '/', $$self;
    return '' if 1 == @path && '' eq $path[0];
    my $index = shift;
    if (0 > $index) {
        $index += @path;
    }
    elsif (! defined $path[0] || ! length $path[0]) {
        $index += 1
    }
    return '' if $index >= @path;
    $index -= 1 if $index == @path - 1 && ! defined $path[$index] || ! length $path[$index];
    return '' unless defined $path[$index] && length $path[$index];
    return $path[$index];
}

sub beginning {
    my $self = shift;
    my ($beginning) = $$self =~ m{^(\/?[^/]*)};
    return $beginning;
}

sub ending {
    my $self = shift;
    my ($ending) = $$self =~ m{([^/]*\/?)$};
    return $ending;
}

sub get {
	my $self = shift;
	return $$self;
}
for (qw(path stringify)) { no strict 'refs'; *$_ = \&get }

sub push {
	my $self = shift;
	$$self = _canonize $$self, @_;
	return $self;
}
for (qw(down)) { no strict 'refs'; *$_ = \&push }

sub child {
	my $self = shift;
	my $child = $self->clone;
	return $child->push(@_);
}

sub append {
    my $self = shift;
    return $self unless @_;
    $self->set($$self . join '/', @_);
    return $self;
}

sub extension {
    my $self = shift;

    my $extension;
    if (@_ && ! defined $_[0]) {
        $extension = '';
    }
    elsif (ref $_[0] eq '') {
        $extension = shift;
    }

    my $options;
    if (ref $_[0] eq 'HASH') {
        $options = shift;
    }
    else {
        $options = { match => shift };
    }

    my $matcher = $options->{match} || 1;
    if ('*' eq $matcher) {
        $matcher = '';
    }
    if (ref $matcher eq 'Regexp') {
    }
    elsif ($matcher eq '' || $matcher =~ m/^\d+$/) {
        $matcher = qr/((?:\.[^\.]+){1,$matcher})$/;
    }
    else {
        $matcher = qr/$matcher/;
    }

    my $ending = $self->ending;
    if (! defined $extension) {
        return '' if $self->is_empty || $self->is_root;
        return join '', $ending =~ $matcher;
    }
    else {
        if ('' eq $extension) {
        }
        elsif ($extension !~ m/^\./) {
            $extension = '.' . $extension;
        }

        if ($self->is_empty || $self->is_root) {
            $self->append($extension);
        }
        else {
            if ($ending =~ s/$matcher/$extension/) {
                $self->pop;
                $self->push($ending);
            }
            else {
                $self->append($extension);
            }
        }
        return $self;
    }
    
}

my %pop_re = (
    '' => qr{(/)?([^/]+)(/)?$},
    '$' => qr{(/)?([^/]+/?)()$},
);

sub _pop {
	my $self = shift;
	return '' if $self->is_empty;
	my $count = shift @_;
    $count = 1 unless defined $count;
    my ($greedy_lead, $re);
    if ($count =~ s/([\^\$\*])$//) {
        $greedy_lead = 1 if $1 ne '$';
        $re = $pop_re{'$'} if $1 ne '^';
    }
    $re = $pop_re{''} unless $re;
    $count = 1 unless length $count;

    {
	    my @popped;
        no warnings 'uninitialized';

        while ($count--) {
            if ($$self =~ s/$re//) {
                my $popped = $2;
                unshift(@popped, $popped) if $popped;
                if (! length $$self) {
                    if ($greedy_lead) {
                        substr $popped[0], 0, 0, $1;
                    }
                    else {
                        $$self .= $1;
                    }
                    last;
                }
            }
            else {
                last;
            }
        }

	    return \@popped;
    }
}

#my %pop_re = (
#    '' => qr{(.)?([^/]+)/?$},
#    '+' => qr{(.)?([^/]+)/?$},
#    '*' => qr{(.)?([^/]+/?)$},
#);

#sub _pop {
#    my $self = shift;
#    return '' if $self->is_empty;
#    my $count = shift @_;
#    $count = 1 unless defined $count;
#    my ($greed, $greed_plus, $greed_star);
#    if ($count =~ s/([+*])$//) {
#        $greed = $1;
#        if ($greed eq '+')  { $greed_plus = 1 }
#        else                { $greed_star = 1 }
#    }
#    else {
#        $greed = '';
#    }
#    my $re = $pop_re{$greed};
#    $count = 1 unless length $count;
#    my @popped;

#    while ($count--) {
#        if ($$self =~ s/$re//) {
#            my $popped = $2;
#            unshift(@popped, $popped) if $popped;
#            if ($1 && $1 eq '/' && ! length $$self) { 
#                if ($greed) {
#                    substr $popped[0], 0, 0, $1;
#                }
#                else {
#                    $$self = $1;
#                }
#                last;
#            }
#            elsif (! $$self) {
#                last;
#            }
#        }
#    }
#    return \@popped;
#}

sub pop {
	my $self = shift;
	return (ref $self)->new('') if $self->is_empty;
    my $popped = $self->_pop(@_);
	return (ref $self)->new(join '/', @$popped);
}

sub up {
    my $self = shift;
    return $self if $self->is_empty;
    $self->_pop(@_);
    return $self;
}

#sub up {
#    my $self = shift;
#    return $self if $self->is_empty;
#    my $count = 1;
#    $count = shift @_ if @_;
#    while (! $self->is_empty && $count--) {
#        if ($$self =~ s/(^|^\/|\/)([^\/]+)$//) {
#            if ($1 && ! length $$self) {
#                $$self = $1;
#                last;
#            }
#            elsif (! $$self) {
#                last;
#            }
#        }
#    }
#    return $self;
#}

sub parent {
	my $self = shift;
	my $parent = $self->clone;
	return $parent->up(1, @_);
}

BEGIN {
	no strict 'refs';
	eval { require Path::Class };
	if ($@) {
		*dir = *file = sub { croak "Path::Class is not available" };
	}
	else {
		*file = sub { return Path::Class::file(shift->get, @_) };
		*dir = sub { return Path::Class::dir(shift->get, @_) };
	}
}

1; # End of Path::Abstract::Underload

__END__
=pod

=head1 NAME

Path::Abstract::Underload - Path::Abstract without stringification overloading

=head1 VERSION

version 0.096

=head1 SYNOPSIS

  use Path::Abstract::Underload;

  my $path = Path::Abstract::Underload->new("/apple/banana");

  # $parent is "/apple"
  my $parent = $path->parent;

  # $cherry is "/apple/banana/cherry.txt"
  my $cherry = $path->child("cherry.txt");

=head1 DESCRIPTION

This is a version of Path::Abstract without the magic "use overload ..." stringification.

Unfortunately, without overloading, you can't do this:

    my $path = Path::Abstract::Underload->new("/a/path/to/somewhere");

    print "$path\n"; # Will print out something like "Path::Abstract::Underload=SCALAR(0xdffaa0)\n"

You'll have to do this instead:

    print $path->get, "\n"; Will print out "/a/path/to/somewhere\n"
    # Note, you can also use $path->stringify or $path->path

    # You could also do this (but it's safer to do one of the above):
    print $$path, "\n";

Or, just use L<Path::Abstract>

=head1 DOCUMENTATION

See L<Path::Abstract> for documentation & usage

=head1 AUTHOR

  Robert Krimen <robertkrimen@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Robert Krimen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

