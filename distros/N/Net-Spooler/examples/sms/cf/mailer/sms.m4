PUSHDIVERT(-1)
#
#   Mailer for SMS gateway, as implemented by Net::Spooler
#

ifdef(`SMS_MAILER_ARGS',,
	`define(`SMS_MAILER_ARGS', smsmail -d $u@$h $f)')
ifdef(`SMS_MAILER_PATH',,
	`define(`SMS_MAILER_PATH', /usr/bin/smsmail)')
ifdef(`SMS_MAILER_MAX',,
	`define(`SMS_MAILER_MAX', 1000000)')
POPDIVERT
####################################
###   SMS Mailer specification   ###
####################################

VERSIONID(`@(#)SMS.m4	19-Aug-1999')

MSMS,		P=SMS_MAILER_PATH, F=DFMhu, S=15, R=25, M=SMS_MAILER_MAX, T=X-Phone/X-SMS/X-Unix,
		A=SMS_MAILER_ARGS

LOCAL_CONFIG
CPSMS
