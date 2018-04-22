use 5.008;
use strict;
use warnings;
package Task::PerlFormance;
# git description: v0.007-1-g7163d42

our $AUTHORITY = 'cpan:SCHWIGON';
# ABSTRACT: Max dependencies for Benchmark::Perl::Formance
$Task::PerlFormance::VERSION = '0.008';

__END__

=pod

=encoding UTF-8

=head1 NAME

Task::PerlFormance - Max dependencies for Benchmark::Perl::Formance

=head1 VERSION

version 0.008

=head1 TASK CONTENTS

=head2 cpan

=head3 L<Digest::SHA1>

=head3 L<Safe>

=head3 L<Module::Build>

=head2 perlformance

=head3 L<Benchmark::Perl::Formance>

=head3 L<Benchmark::Perl::Formance::Cargo>

=head3 L<Benchmark::Perl::Formance::Plugin::PerlStone2015>

=head3 L<Benchmark::Perl::Formance::Plugin::Mandelbrot>

=head3 L<BenchmarkAnything::Reporter>

=head3 L<Test::More>

=head3 L<File::ShareDir>

=head2 OO

=head3 L<Moose>

=head3 L<Mouse>

=head3 L<Moo>

=head3 L<Class::Accessor>

=head3 L<Class::Accessor::Fast>

=head3 L<Class::MethodMaker>

=head3 L<Object::Tiny::RW>

=head3 L<Class::XSAccessor>

=head3 L<Class::XSAccessor::Array>

=head2 RxCmp

=head3 L<POSIX::Regex>

=head3 L<ExtUtils::CppGuess>

=head3 L<re::engine::Lua>

# =pkg re::engine::Plan9

# =pkg re::engine::Oniguruma

=head3 L<re::engine::RE2>

=head3 L<re::engine::PCRE>

=head2 Regex

=head3 L<Regexp::Common>

=head3 L<DateTime::Calendar::Mayan>

=head3 L<Locale::US>

=head3 L<HTTP::Headers>

=head3 L<URI>

=head2 Incubator

=head3 L<Math::MatrixReal>

=head2 Shootout

=head3 L<Math::GMP>

=head2 Primes

=head3 L<Crypt::Primes>

=head3 L<Math::Primality>

=head2 DPath

=head3 L<Clone>

=head3 L<Devel::Size>

=head3 L<Data::DPath>

=head2 P6STD

=head3 L<Text::Balanced>

=head3 L<YAML::XS>

=head3 L<Encode>

=head2 SpamAssassin

=head3 L<AAAA::Mail::SpamAssassin>

=head3 L<Mail::SpamAssassin>

1;

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
