#! /bin/false

# Copyright (C) 2016-2017 Guido Flohr <guido.flohr@cantanea.com>,
# all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU Library General Public License as published
# by the Free Software Foundation; either version 2, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.

# You should have received a copy of the GNU Library General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307,
# USA.

# ABSTRACT: Gettext Support For the Template Toolkit Version 2

package Template::Plugin::Gettext;

use strict;

our $VERSION = 0.1;

use Locale::TextDomain 1.20 qw(com.cantanea.Template-Plugin-Gettext);
use Locale::Messages;
use Locale::Util qw(web_set_locale);

use Cwd qw(abs_path);

use base qw(Template::Plugin);

my %bound_dirs;
our @DEFAULT_DIRS;
our @LOCALE_DIRS;

sub __find_domain($);
sub __expand($%);

BEGIN {
    foreach my $dir (qw('/usr/share/locale /usr/local/share/locale')) {
        if (-d $dir) {
            push @DEFAULT_DIRS, $dir;
            last;
        }
    }
}

sub new {
    my ($class, $ctx, $textdomain, $language, $charset, @search_dirs) = @_;

    my $self = bless {}, $class;

    $textdomain = 'textdomain' unless defined $textdomain && length $textdomain;
    $charset = 'utf-8' unless defined $charset && length $charset;

    unless (exists $bound_dirs{$textdomain}) {
        unless (@search_dirs) {
            @search_dirs = map $_ . '/LocaleData', @INC;
            push @search_dirs, @DEFAULT_DIRS;
        }
        unshift @search_dirs, @LOCALE_DIRS;
        $bound_dirs{$textdomain} = [@search_dirs];
    }

    $self->{__textdomain} = $textdomain;
    $self->{__locale} = web_set_locale $language, $charset if defined $language;

    $ctx->define_filter(gettext => sub {
        my ($context) = @_;

        return sub {
            return __gettext($textdomain, shift);
        };
    }, 1);
    $ctx->define_filter(ngettext => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __ngettext($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(pgettext => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __pgettext($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(gettextp => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __gettextp($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(npgettext => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __npgettext($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(ngettextp => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __ngettextp($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(xgettext => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __xgettext($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(nxgettext => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __nxgettext($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(pxgettext => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __pxgettext($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(xgettextp => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __xgettextp($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(npxgettext => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __npxgettext($textdomain, shift, @args);
        };
    }, 1);
    $ctx->define_filter(nxgettextp => sub {
        my ($context, @args) = @_;
        my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};

        push @args, %$pairs;
        return sub {
            return __nxgettextp($textdomain, shift, @args);
        };
    }, 1);

    return $self;
}

sub __gettext {
    my ($textdomain, $msgid) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return Locale::Messages::dgettext($textdomain => $msgid);
}

sub gettext {
    my ($self, $msgid) = @_;

    return __gettext $self->{__textdomain}, $msgid;
}

sub __ngettext {
    my ($textdomain, $msgid, $msgid_plural, $count) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return Locale::Messages::dngettext($textdomain => $msgid, $msgid_plural,
                                       $count);
}

sub ngettext {
    my ($self, $msgid, $msgid_plural, $count) = @_;

    return __ngettext $self->{__textdomain}, $msgid, $msgid_plural, $count;
}

sub __pgettext {
    my ($textdomain, $context, $msgid) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return Locale::Messages::dpgettext($textdomain => $context, $msgid);
}

sub pgettext {
    my ($self, $context, $msgid) = @_;

    return __pgettext $self->{__textdomain}, $context, $msgid;
}

sub __gettextp {
    my ($textdomain, $msgid, $context) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return Locale::Messages::dpgettext($textdomain => $context, $msgid);
}

sub gettextp {
    my ($self, $msgid, $context) = @_;

    return __gettextp $self->{__textdomain}, $msgid, $context;
}

sub __npgettext {
    my ($textdomain, $context, $msgid, $msgid_plural, $count) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return Locale::Messages::dnpgettext($textdomain => $context, $msgid,
                                        $msgid_plural, $count);
}

sub npgettext {
    my ($self, $context, $msgid, $msgid_plural, $count) = @_;

    return __npgettext $self->{__textdomain}, $context, $msgid, $msgid_plural,
                       $count;
}

sub __ngettextp {
    my ($textdomain, $msgid, $msgid_plural, $count, $context) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return Locale::Messages::dnpgettext($textdomain => $context, $msgid,
                                        $msgid_plural, $count);
}

sub ngettextp {
    my ($self, $msgid, $msgid_plural, $count, $context) = @_;

    return __ngettextp $self->{__textdomain}, $msgid, $msgid_plural, $count,
                       $context;
}

sub __xgettext {
    my ($textdomain, $msgid, %vars) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return __expand((Locale::Messages::dgettext($textdomain => $msgid)), %vars);
}

sub xgettext {
    my ($self, $msgid, @args) = @_;
 
    my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};
    push @args, %$pairs;

    return __xgettext $self->{__textdomain}, $msgid, @args;
}

sub __nxgettext {
    my ($textdomain, $msgid, $msgid_plural, $count, %vars) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return __expand((Locale::Messages::dngettext($textdomain => $msgid,
                                                 $msgid_plural, $count)), 
                    %vars);
}

sub nxgettext {
    my ($self, $msgid, $msgid_plural, $count, @args) = @_;

    my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};
    push @args, %$pairs;

    return __nxgettext $self->{__textdomain}, $msgid, $msgid_plural, $count, 
                       @args;
}

sub __pxgettext {
    my ($textdomain, $context, $msgid, %vars) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return __expand((Locale::Messages::dpgettext($textdomain => $context, 
                                                 $msgid)), 
                    %vars);
}

sub pxgettext {
    my ($self, $context, @args) = @_;
 
    my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};
    push @args, %$pairs;

    return __pxgettext $self->{__textdomain}, $context, @args;
}

sub __xgettextp {
    my ($textdomain, $msgid, $context, %vars) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return __expand((Locale::Messages::dpgettext($textdomain => $context, 
                                                 $msgid)), 
                    %vars);
}

sub xgettextp {
    my ($self, $msgid, @args) = @_;
 
    my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};
    push @args, %$pairs;

    return __xgettextp $self->{__textdomain}, $msgid, @args;
}

sub __npxgettext {
    my ($textdomain, $context, $msgid, $msgid_plural, $count, %vars) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return __expand((Locale::Messages::dnpgettext($textdomain => $context, 
                                                 $msgid, $msgid_plural,
                                                 $count)), 
                    %vars);
}

sub npxgettext {
    my ($self, $context, @args) = @_;
 
    my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};
    push @args, %$pairs;

    return __npxgettext $self->{__textdomain}, $context, @args;
}

sub __nxgettextp {
    my ($textdomain, $msgid, $msgid_plural, $count, $context, %vars) = @_;

    __find_domain $textdomain
        if defined $textdomain && exists $bound_dirs{$textdomain};

    return __expand((Locale::Messages::dnpgettext($textdomain => $context, 
                                                 $msgid, $msgid_plural,
                                                 $count)), 
                    %vars);
}

sub nxgettextp {
    my ($self, $msgid, @args) = @_;
 
    my $pairs = ref $args[-1] eq 'HASH' ? pop(@args) : {};
    push @args, %$pairs;

    return __nxgettextp $self->{__textdomain}, $msgid, @args;
}

sub debug_locale {
    shift->{__locale};
}

sub __expand($%) {
    my ($str, %vars) = @_;

    my $re = join '|', map { quotemeta } keys %vars;
    $str =~ s/\{($re)\}/exists $vars{$1} ? 
        (defined $vars{$1} ? $vars{$1} : '') : "{$1}"/ge;

    return $str;
}

sub __find_domain($) {
    my ($domain) = @_;

    my $try_dirs = $bound_dirs{$domain};

    if (defined $try_dirs) {
        my $found_dir = '';

        TRYDIR: foreach my $dir (map {abs_path $_} grep { -d $_ } @$try_dirs) {
            # Is there a message catalog?

            local *DIR;
            if (opendir DIR, $dir) {
                 my @files = map { "$dir/$_/LC_MESSAGES/$domain.mo" }
                             grep { ! /^\.\.?$/ } readdir DIR;
                 foreach my $file (@files) {
                     if (-f $file || -l $file) {
                         $found_dir = $dir;
                         last TRYDIR;
                     }
                 }
            }
        }

        # If $found_dir is undef, the default search directories are
        # used.
        Locale::Messages::bindtextdomain($domain => $found_dir);
    }

    delete $bound_dirs{$domain};

    return 1;
}

1;
