package SPVM::Go::Error::IOTimeout;



1;

=head1 Name

SPVM::Go::Error::IOTimeout - Error for Goroutine IO Timeout

=head1 Description

Go::Error::IOTimeout class in L<SPVM> represent an error for goroutine IO timeout.

=head1 Usage
  
  if ($@) {
    if (eval_error_id isa Go::Error::IOTimeout) {
      
    }
  }
  
=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

