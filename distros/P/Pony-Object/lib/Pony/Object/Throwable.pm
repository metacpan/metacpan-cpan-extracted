# Class: Pony::Object::Throwable
#   Simplest Exception class.

# "The owls are not what they seem"
package Pony::Object::Throwable {
  use Pony::Object;
  
  protected message => '';
  protected package => '';
  protected file    => '';
  protected line    => '';
  
  # Method: throw
  #   Say "hello" and raise Exception.
  #
  # Parameters:
  #   $this - Str||Pony::Object - self
  #   $message - Str - some funny message for poor users.
  sub throw : Public {
    my $this = shift; # pkg || obj
    $this = $this->new unless ref $this;
    $this->message = shift || "no comments";
    ($this->package, $this->file, $this->line) = @_ || caller;
    
    printf STDERR "\n\"%s\" at %s (%s:%s)\n",
      $this->message, $this->package, $this->file, $this->line;
    
    die $this;
  }
}

1;

__END__

=pod

=head1 NAME

Pony::Object::Throwable - A base throwable object.

=head1 OVERVIEW

Pony::Object::Throwable objects has C<throw> method which throws an exception.

=head2 Exceptions

Do you want to use Pony exceptions in your code? There is nothing easier! Use block
C<try> to wrap code with possible exceptions, block C<catch> to catch exceptions
and C<finally> to define code, which should be runned after all.

When we talk about exceptions we mean special type of Perl's C<die>.
Base class for all pony-exceptions is Pony::Object::Throwable. It has one method
C<throw>. It should be used on exceptions in the program.

Use C<:exceptions> (or C<:try>) param to enable try/catch/finally blocks.
Use C<:noexceptions> (or C<notry>) param to disable them.

Nested try works for perl-5.14 or higher.

=head1 SYNOPSIS

  package MyFile {
    use Pony::Object qw/:exceptions/;
    
    protected 'file';
    protected 'data' => undef;
    
    sub init : Public($this, $file) {
      $this->file = $file;
    }
    
    sub read : Public($this) {
      $this->data = try {
        open F, $this->file or
          throw Pony::Object::Throwable("Can't find $file.");
        local $/;
        my $data = <F>;
        close F;
        return $data;
      } catch {
        my $e = shift; # get exception object
        say "Exception catched!";
        say $e->dump();
        return undef;
      };
    }
  }
  
  1;

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 - 2017, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
