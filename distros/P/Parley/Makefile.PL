#!/usr/bin/env perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;
use inc::Module::Install;

name            ('Parley');
author          ('Chisel Wright<chiselwright@users.berlios.de>');
abstract        ('Message board / forum application');
license         ('perl');
version         ('1.2.1');

requires(
    'Catalyst'                                                  => '5.80001',
    'Catalyst::Runtime'                                         => '5.80001',
    'Catalyst::Action::RenderView'                              => '0.08',
    'Catalyst::Authentication::Store::DBIx::Class'              => '0.10',
    'Catalyst::Controller::reCAPTCHA'                           => '0.30001',
    'Catalyst::Controller::Validation::DFV'                     => '0.0.5',
    'Catalyst::Model::DBIC::Schema'                             => '0.20',
    'Catalyst::Plugin::Authorization::ACL'                      => '0.08',
    'Catalyst::Plugin::Authorization::Roles'                    => '0.05',
    'Catalyst::Plugin::ConfigLoader'                            => '0.20',
    'Catalyst::Plugin::Email'                                   => '0.08',
    'Catalyst::Plugin::FillInForm'                              => '0.09',
    'Catalyst::Plugin::FormValidator'                           => '0.02',
    'Catalyst::Plugin::I18N'                                    => '0.07',
    'Catalyst::Plugin::Session'                                 => '0.19',
    'Catalyst::Plugin::Session::State::Cookie'                  => '0.09',
    'Cache::FastMmap'                                           => '1.24',
    'Catalyst::Plugin::Session::Store::DBIC'                    => '0.06',
    'Catalyst::Plugin::StackTrace'                              => '0.08',
    'Catalyst::Plugin::Static::Simple'                          => '0.20',
    'Catalyst::View::TT'                                        => '0.27',
    'Catalyst::View::JSON'                                      => '0.24',
    'Config::General'                                           => '2.37',
    'Data::FormValidator'                                       => '4.50',
    'Data::SpreadPagination'                                    => '0.1.2',
    'Date::Manip'                                               => '5.54',
    'DateTime'                                                  => '0.41',
    'DateTime::Format::Pg'                                      => '0.16001',
    'DateTime::TimeZone'                                        => '0.70',
    'Email::Valid'                                              => '0.179',
    'Image::Magick'                                             => 0,
    'HTML::FillInForm'                                          => '1.07',
    'Image::Size'                                               => '3.1',
    'JSON'                                                      => '2.04',
    'List::MoreUtils'                                           => '0.21',
    'MIME::Lite'                                                => '3.020',
    'Net::IP::Match::Regexp'                                    => '1.00',
    'Perl6::Export::Attrs'                                      => '0.0.3',
    'Proc::Daemon'                                              => '0.03',
    'Proc::PID::File'                                           => '1.2.4',
    'Readonly'                                                  => 0,
    'Template::Plugin::ForumCode'                               => '0.0.5',
    'Text::Context::EitherSide'                                 => '1.3',
    'Time::Piece'                                               => '1.11',
);

build_requires (
    'Test::Aggregate'                                           => '0.35',
    'Test::More'                                                => 0,
    'Test::WWW::Mechanize::Catalyst'                            => 0,
    'Test::DBIx::Class::Schema'                                 => '0.01004',
);

tests_recursive;

catalyst;

install_script glob('script/*.pl');
#auto_install;
WriteAll;
