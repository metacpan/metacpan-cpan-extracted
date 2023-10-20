package Template::Liquid::Context;
our $VERSION = '1.0.23';
require Template::Liquid::Utility;
require Template::Liquid::Error;
use strict;
use warnings;
use Scalar::Util;

sub new {
    my ($class, %args) = @_;
    return bless {scopes   => [$args{assigns}],
                  template => $args{template},    # Required
                  errors   => []
    }, $class;
}

sub push {
    my ($s, $context) = @_;
    return
        raise Template::Liquid::Error {type     => 'Stack',
                                       template => $s->{template},
                                       message  => 'Cannot push new scope!'
        }
        if scalar @{$s->{'scopes'}} == 100;
    return push @{$s->{'scopes'}}, (defined $context ? $context : {});
}

sub pop {
    my ($s) = @_;
    return
        raise Template::Liquid::Error {type     => 'Stack',
                                       template => $s->{template},
                                       message  => 'Cannot pop scope!'
        }
        if scalar @{$s->{'scopes'}} == 1;
    return pop @{$s->{'scopes'}};
}

sub stack {
    my ($s, $block) = @_;
    my $old_scope = $s->{scopes}[-1];
    $s->push();
    $s->merge($old_scope);
    my $result = $block->($s);
    $s->pop;
    return $result;
}

sub merge {
    my ($s, $new) = @_;
    return $s->{'scopes'}->[0] = __merge(reverse $s->{scopes}[-1], $new);
}

sub _merge {    # Deeply merges data structures
    my ($source, $target) = @_;
    my $return = $target;
    for (keys %$source) {
        if ('ARRAY' eq ref $target->{$_} &&
            ('ARRAY' eq ref $source->{$_} || !ref $source->{$_})) {
            @{$return->{$_}} = [@{$target->{$_}}, @{$source->{$_}}];
        }
        elsif ('HASH' eq ref $target->{$_} &&
               ('HASH' eq ref $source->{$_} || !ref $source->{$_})) {
            $return->{$_} = _merge($source->{$_}, $target->{$_});
        }
        else { $return->{$_} = $source->{$_}; }
    }
    return $return;
}
my $merge_precedent;

sub __merge {    # unless right is more interesting, this is a left-
    my $return = $_[1];    # precedent merge function
    $merge_precedent ||= {
        SCALAR => {SCALAR => sub { defined $_[0] ? $_[0] : $_[1] },
                   ARRAY  => sub { $_[1] },
                   HASH   => sub { $_[1] },
        },
        ARRAY => {
            SCALAR => sub {
                [@{$_[0]}, defined $_[1] ? $_[1] : ()];
            },
            ARRAY => sub { [@{$_[0]}] },
            HASH  => sub { [@{$_[0]}, values %{$_[1]}] },
        },
        HASH => {SCALAR => sub { $_[0] },
                 ARRAY  => sub { $_[0] },
                 HASH   => sub { _merge($_[0], $_[1], $_[2]) },
        }
    };
    for my $key (keys %{$_[0]}) {
        my ($left_ref, $right_ref)
            = map { ref($_->{$key}) =~ m[^(HASH|ARRAY)$]o ? $1 : 'SCALAR' }
            ($_[0], $_[1]);

        #warn sprintf '%-12s [%6s|%-6s]', $key, $left_ref, $right_ref;
        $return->{$key} = $merge_precedent->{$left_ref}{$right_ref}
            ->($_[0]->{$key}, $_[1]->{$key});
    }
    return $return;
}

sub get {
    my ($s, $var) = @_;
    return    if !defined $var;
    return $2 if $var =~ m[^(["'])(.+)\1$]o;
    my @path = split $Template::Liquid::Utility::VariableAttributeSeparator,
        $var;
    my $cursor = \$s->{scopes}[-1];
    return $var
        if $var =~ m[^[-\+]?(\d*\.)?\d+$]o && !exists $$cursor->{$path[0]};
    return     if $var eq '';
    return ''  if $var eq '""';
    return ""  if $var eq "''";
    return     if $var eq 'null';
    return     if $var eq 'nil';
    return     if $var eq 'blank';
    return     if $var eq 'empty';
    return !1  if $var eq 'false';
    return !!1 if $var eq 'true';

    if ($var =~ m[^\((\S+)\s*\.\.\s*(\S+)\)$]o) {
        return [$s->get($1) .. $s->get($2)];    # range
    }

#    print STDERR "DEBUG:var=$var. about to get 1 and 2 from regex";
# return $s->get($1)->[$2] if $var =~ m'^(.+)\[(\d+)\]$'o; # array index  myvar[2]
    if ($var =~ m'^(.+)\[(\d+)\]$'o) {

        #	    print STDERR "DEBUG:array index. var=$var. 1=$1,2=$2";
        my $arr = $s->get($1);
        return $arr->[$2] if $arr;
        return;    # return if nothing
    }

    # return $s->get($1)->{$2} if $var =~ m'^(.+)\[(.+)\]$'o;
    if ($var =~ m'^(.+)\[(.+)\]$'o) {

        #	    print STDERR "DEBUG:obj property. var=$var. 1=$1,2=$2";
        my $obj = $s->get($1);
        return $obj->{$2} if $obj;
        return;    # return if nothing
    }
STEP: while (@path) {
        my $crumb   = shift @path;
        my $reftype = ref $$cursor;
        if (Scalar::Util::blessed($$cursor) && $$cursor->can($crumb)) {
            my $can = $$cursor->can($crumb);
            my $val = $can->($$cursor);
            return $val if !scalar @path;
            $cursor = \$val;
            next STEP;
        }
        elsif ($reftype eq 'HASH') {
            if (exists $$cursor->{$crumb}) {
                return $$cursor->{$crumb} if !@path;
                $cursor = \$$cursor->{$crumb};
                next STEP;
            }
            return ();
        }
        elsif ($reftype eq 'ARRAY') {
            return scalar @{$$cursor} if $crumb eq 'size';
            $crumb = 0          if $crumb eq 'first';
            $crumb = $#$$cursor if $crumb eq 'last';
            return ()                 if $crumb =~ m[\D]o;
            return ()                 if scalar @$$cursor < $crumb;
            return $$cursor->[$crumb] if !scalar @path;
            $cursor = \$$cursor->[$crumb];
            next STEP;
        }
        return ();
    }
}

sub set {
    my ($s, $var, $val) = @_;
    my $var_reftype = ref $val;
    my @path = split $Template::Liquid::Utility::VariableAttributeSeparator,
        $var;
    my $cursor = \$s->{scopes}[-1];
    $cursor = \$$cursor->{shift @path} if (exists $$cursor->{$path[0]});
STEP: while (@path) {
        my $crumb   = shift @path;
        my $reftype = ref $$cursor;
        if ($reftype eq 'HASH') {
            if (!@path) {
                if (exists $$cursor->{$crumb}) {

                    # TODO: If the reftype is different, mention it
                }
                return $$cursor->{$crumb} = $val;
            }
            else {
                $$cursor->{$crumb} = $path[0] =~ m[\D] ? {} : []
                    if !exists $$cursor->{$crumb};
                $cursor = \$$cursor->{$crumb};
                next STEP;
            }
        }
        elsif ($reftype eq 'ARRAY') {
            if ($crumb =~ m[\D]) {

                # TODO: Let the user know
            }
            if (!@path) {
                if (exists $$cursor->[$crumb]) {

                    # TODO: If the reftype is different, mention it
                }
                return $$cursor->[$crumb] = $val;
            }
            else {
                $$cursor->[$crumb] = $path[0] =~ m[\D] ? {} : []
                    if !exists $$cursor->[$crumb];
                $cursor = \$$cursor->[$crumb];
                next STEP;
            }
        }
        else {
            if (!@path) {
                if ($crumb =~ m[\D]) {
                    $$cursor = {};
                    return $$cursor->{$crumb} = $val;
                }
                $$cursor = [];
                return $$cursor->[$crumb] = $val;
            }
            else {
                $$cursor->{$crumb} = $path[0] =~ m[\D] ? {} : []
                    if !exists $$cursor->[$crumb];
                $cursor = \$$cursor->{$crumb};
                next STEP;
            }
        }
    }
    return $$cursor = $val;
}
1;

=pod

=encoding UTF-8

=head1 NAME

Template::Liquid::Context - Complex Variable Keeper

=head1 Description

This is really only to be used internally.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2009-2022 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of L<The Artistic License
2.0|http://www.perlfoundation.org/artistic_license_2_0>. See the F<LICENSE>
file included with this distribution or L<notes on the Artistic License
2.0|http://www.perlfoundation.org/artistic_2_0_notes> for clarification.

When separated from the distribution, all original POD documentation is covered
by the L<Creative Commons Attribution-Share Alike 3.0
License|http://creativecommons.org/licenses/by-sa/3.0/us/legalcode>. See the
L<clarification of the
CCA-SA3.0|http://creativecommons.org/licenses/by-sa/3.0/us/>.

=cut
