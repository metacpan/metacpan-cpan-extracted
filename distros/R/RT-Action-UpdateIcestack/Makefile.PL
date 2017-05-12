# Copyright (c) 2013 Experieco Ltd. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

use inc::Module::Install;

RTx('RT-Action-UpdateIcestack');
readme_from('lib/RT/Action/UpdateIcestack.pm');
requires('Date::Manip');
requires('HTTP::Request::Common');
requires('LWP::UserAgent');
requires('MIME::Base64');
requires('XML::LibXML');

&WriteAll;
