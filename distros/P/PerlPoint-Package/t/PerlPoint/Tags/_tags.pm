

# = HISTORY SECTION =====================================================================

# ---------------------------------------------------------------------------------------
# version | date     | author   | changes
# ---------------------------------------------------------------------------------------
# 0.04    |27.12.2004| JSTENZEL | updated to new \REF implementation;
# 0.03    |< 14.04.02| JSTENZEL | added simple versions of \I, \B and \C;
# 0.02    |13.10.2001| JSTENZEL | added copy of PerlPoint::Tags::Basic tag \REF;
# 0.01    |20.03.2001| JSTENZEL | new.
# ---------------------------------------------------------------------------------------

# pragmata
use strict;

# declare a helper package to declare tags
package PerlPoint::Tags::_tags;

# declare base "class"
use base qw(PerlPoint::Tags);

# declare global
use vars qw(%tags %sets);

# load modules
use PerlPoint::Constants qw(:parsing :tags);

# declare tags
%tags=(
       FONT => {
                 options    => TAGS_MANDATORY,
                 body       => TAGS_MANDATORY,
                },
       TEST  => {
                 options => TAGS_OPTIONAL,
                },

       TOAST => {
                 options => TAGS_OPTIONAL,
                },

       B     => {body => TAGS_MANDATORY,},
       C     => {body => TAGS_MANDATORY,},
       I     => {body => TAGS_MANDATORY,},

       # resolve a reference (copied from PerlPoint::Tags::Basic 0.02)
       # (this is used to check hook invokation and anchor management)
       REF   => {
                 # at least one option is required
                 options => TAGS_MANDATORY,

                 # there can be a body
                 body    => TAGS_OPTIONAL,

                 # hook!
                 hook    => sub
                             {
                              # declare and init variable
                              my $ok=PARSING_OK;

                              # take parameters
                              my ($tagLine, $options, $body, $anchors)=@_;

                              # check them (a name must be specified at least)
                              $ok=PARSING_FAILED, warn qq(\n\n[Error] Missing "name" option in REF tag, line $tagLine.\n) unless exists $options->{name};

                              $ok=PARSING_FAILED, warn qq(\n\n[Error] Invalid "type" setting "$options->{type}" in REF tag, line $tagLine.\n)
                                if     exists $options->{type}
                                   and $options->{type}!~/^(linked|plain)$/;

                              $ok=PARSING_FAILED, warn qq(\n\n[Error] Invalid "valueformat" setting "$options->{valueformat}" in REF tag, line $tagLine.\n)
                                if     exists $options->{valueformat}
                                   and $options->{valueformat}!~/^(pure|pagetitle|pagenr)$/;

                              # set defaults, if necessary
                              $options->{type}='plain' unless exists $options->{type};
                              $options->{valueformat}='pure' unless exists $options->{valueformat};

                              # store a body hint
                              $options->{__body__}=@$body ? 1 : 0;

                              # format address to simplify anchor search
                              $options->{name}=~s/\s*\|\s*/\|/g if exists $options->{name};

                              # supply status
                              $ok;
                             },

                 # afterburner
                 finish =>  sub
                             {
                              # declare and init variable
                              my $ok=PARSING_OK;

                              # take parameters
                              my ($options, $anchors)=@_;

                              # try to find an alternative, if possible
                              if (exists $options->{alt} and not $anchors->query($options->{name}))
                                {
                                 foreach my $alternative (split(/\s*,\s*/, $options->{alt}))
                                   {
                                    if ($anchors->query($alternative))
                                      {
                                       warn qq(\n\n[Info] Unknown link address "$options->{name}" is replaced by alternative "$alternative" in REF tag.\n);
                                       $options->{name}=$alternative;
                                       last;
                                      }
                                   }
                                }

                              # check link for being valid - finally
                              unless ($anchors->query($options->{name}))
                                {
                                 # allowed case?
                                 if (exists $options->{occasion} and $options->{occasion})
                                   {
                                    $ok=PARSING_IGNORE;
                                    warn qq(\n\n[Info] Unknown link address "$options->{name}": REF tag ignored.\n);
                                   }
                                 else
                                   {
                                    $ok=PARSING_FAILED;
                                    warn qq(\n\n[Error] Unknown link address "$options->{name}" in REF tag.\n);
                                   }
                                }
                              else
                                {
                                 # link ok, get value and chapter number
                                 @{$options}{qw(__value__ __chapter__)}=@{$anchors->query($options->{name})->{$options->{name}}};
                                }

                              # supply status
                              $ok;
                             },
                },

      );

# flag success
1;
