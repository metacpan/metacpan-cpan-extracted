##############################################################################
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Library General Public License for more details.
#
#  You should have received a copy of the GNU Library General Public
#  License along with this library; if not, write to the
#  Free Software Foundation, Inc., 59 Temple Place - Suite 330,
#  Boston, MA  02111-1307, USA.
#
#  Copyright (C) 2003-2005 Ryan Eatmon
#
##############################################################################

#
# This class was borrowed from the IO::Capture module by Mark Reynolds and
# Jon Morgan.  I do not need all the capability of IO::Capture, nor do I
# want to create a depenency on too many external modules.  Thanks to Mark
# and Jon for the great work.
#

package Net::HTTPServer::CaptureSTDOUT;

sub TIEHANDLE {
    my $class = shift;
    bless [], $class;
}

sub PRINT {
    my $self = shift;
    push @$self, join '',@_;
}

sub READLINE {
    my $self = shift;
    return wantarray ? @$self : shift @$self;
}

sub CLOSE {
    my $self = shift;
    return close $self;
}

1;

