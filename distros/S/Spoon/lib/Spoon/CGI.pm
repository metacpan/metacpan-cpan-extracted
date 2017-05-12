package Spoon::CGI;
use Spoon::Base -Base;
use CGI -no_debug, -nosticky;
our @EXPORT = qw(cgi);

my $all_params_by_class = {};

const class_id => 'cgi';

sub cgi() {
    my $package = caller;
    my ($field, $is_upload, @flags);
    for (@_) {
        if ($_ eq '-upload') {
            $is_upload = 1;
            next;
        }
        (push @flags, $1), next if /^-(\w+)$/;
        $field ||= $_;
    }
    die "Cannot apply flags to upload field ($field)" if $is_upload and @flags;
    push @{$all_params_by_class->{$package}}, $field;
    no strict 'refs';
    no warnings;
    *{"$package\::$field"} = $is_upload
    ? sub {
        my $self = shift;
        $self->_get_upload($field);
    }
    : @flags 
    ? sub {
        my $self = shift;
        die "Setting CGI params not implemented" if @_;
        my $param = $self->_get_raw($field);
        for my $flag (@flags) {
            my $method = "_${flag}_filter";
            $self->$method($param);
        }
        return $param;
    } 
    : sub { 
        my $self = shift;
        die "Setting CGI params not implemented" if @_;
        $self->_get_raw($field);
    } 
}

sub add_params {
    my $class = ref($self);
    push @{$all_params_by_class->{$class}}, @_;
}

sub defined {
    my $param = shift;
    defined CGI::param($param) or defined CGI::url_param($param);
}

sub all {
    my $class = ref($self);
    map { ($_, scalar $self->$_) } @{$all_params_by_class->{$class}};
}

sub vars {
    map $self->utf8_decode($_), CGI::Vars();
}

sub _get_raw {
    my $field = shift;

    my @values;
    if (defined(my $value = $self->{$field})) {
        @values = ref($value)
          ? @$value
          : $value;
    }
    else {
        @values = defined CGI::param($field)
          ? CGI::param($field)
          : CGI::url_param($field);

        $self->utf8_decode($_)
          for grep defined, @values;

        $self->{$field} = @values > 1
          ? \@values
          : $values[0];
    }

    return wantarray
      ? @values 
      : defined $values[0]
        ? $values[0]
        : ''; 
}

sub _get_upload {
    my $handle = CGI::upload($_[0])
      or return;
    {handle => $handle, filename => $handle, %{CGI::uploadInfo($handle) || {}}};
}

sub _utf8_filter {
    # This is left in for backwards compatibility
}

sub _trim_filter {
    $_[0] =~ s/^\s*(.*?)\s*$/$1/mg;
    $_[0] =~ s/\s+/ /g;
}

sub _newlines_filter {
    if (length $_[0]) {
        $_[0] =~ s/\015\012/\n/g;
        $_[0] =~ s/\015/\n/g;
        $_[0] .= "\n"
          unless $_[0] =~ /\n\z/;
    }
}

__END__

=head1 NAME 

Spoon::CGI - Spoon CGI Base Class

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2004. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
