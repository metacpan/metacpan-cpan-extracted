/**
 * Speech::Swift - Swift Text-To-Speech for PERL
 *
 * Copyright (c) 2011, Mike Pultz <mike@mikepultz.com>.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *
 *   * Neither the name of Mike Pultz nor the names of his contributors
 *     may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRIC
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * @author      Mike Pultz <mike@mikepultz.com>
 * @copyright   2011 Mike Pultz <mike@mikepultz.com>
 * @license     http://www.opensource.org/licenses/bsd-license.php  BSD License
 * @version     SVN $id$
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include "swift.h"

typedef struct  cst_wave_struct {
    const char *type;
    int sample_rate;
    int num_samples;
    int num_channels;
    short *samples;
} cst_wave;

MODULE = Speech::Swift		PACKAGE = Speech::Swift

int
swift_failed(_res)
		swift_result_t _res
	CODE:
		RETVAL = SWIFT_FAILED(_res) ? 1 : 0;
	OUTPUT:
		RETVAL

const char*
swift_strerror(_res)
	swift_result_t _res

#
# engine functions
#
swift_engine*
swift_engine_open(_params)
	swift_params *_params

void
swift_engine_close(_engine)
	swift_engine *_engine

void
swift_engine_set_voice_retention_policy(_engine, _policy)
	swift_engine *_engine
	swift_voice_retention_policy_t _policy

swift_voice_retention_policy_t
swift_engine_get_voice_retention_policy(_engine)
	swift_engine *_engine

#
# port functions
#
swift_port*
swift_port_open(_engine, _params)
	swift_engine *_engine
	swift_params *_params

swift_result_t
swift_port_done_on_thread(_port)
	swift_port *_port

void
swift_port_close(_port)
	swift_port *_port

const char*
swift_port_language_encoding(_port)
	swift_port *_port

swift_result_t
swift_port_load_sfx(_port, _file)
	swift_port *_port
	const char *_file


#
# event functions
#
const char*
swift_event_type_get_name(_type)
	swift_event_t _type

swift_event_t
swift_event_name_get_type(_name)
	const char *_name


#
# param functions
#
swift_params*
swift_params_new()
	CODE:
		RETVAL = swift_params_new(NULL);
	OUTPUT:
		RETVAL

void
swift_params_set_string(_params, _name, _value)
	swift_params *_params
	char *_name
	char *_value

void
swift_params_set_int(_params, _name, _value)
	swift_params *_params
	char *_name
	int _value

#
# voice functions
#
swift_voice*
swift_port_find_first_voice(_port, _search_criteria, _order_criteria)
	swift_port *_port
	const char *_search_criteria
	const char *_order_criteria

swift_voice*
swift_port_find_next_voice(_port)
	swift_port *_port

swift_voice*
swift_port_rewind_voices(_port)
	swift_port *_port

swift_result_t
swift_port_set_voice(_port, _voice)
	swift_port *_port
	swift_voice *_voice

swift_voice*
swift_port_set_voice_by_name(_port, _voice)
	swift_port *_port
	const char *_voice

swift_voice*
swift_port_set_voice_from_dir(_port, _dir)
	swift_port *_port
	const char *_dir

swift_voice*
swift_port_get_current_voice(_port)
	swift_port *_port

const char*
swift_voice_get_attribute(_voice, _name)
	swift_voice *_voice
	char *_name

swift_result_t
swift_voice_get_attributes(_voice, _params)
	swift_voice *_voice
	swift_params *_params

swift_result_t
swift_voice_load_lexicon(_voice, _file)
	swift_voice *_voice
	const char *_file

#
# wave file functions
#
swift_waveform*
swift_port_get_wave(_port, _text)
		swift_port *_port
		const void *_text
	CODE:
		RETVAL = swift_port_get_wave(_port, _text, strlen(_text), NULL, 0, NULL);
	OUTPUT:
		RETVAL
			
swift_waveform*
swift_waveform_new()

swift_result_t
swift_waveform_save(_wave, _filename, _format)
	swift_waveform *_wave
	const char *_filename
	const char *_format

int
swift_waveform_get_sps(_wave)
	swift_waveform *_wave

const char*
swift_waveform_get_encoding(_wave)
	swift_waveform *_wave

int
swift_waveform_get_channels(_wave)
		swift_waveform *_wave
	CODE:
		RETVAL = _wave->num_channels;
	OUTPUT:
		RETVAL

swift_result_t
swift_waveform_resample(_wave, _new_sps)
	swift_waveform *_wave
	int _new_sps

swift_result_t
swift_waveform_convert(_wave, _encoding)
	swift_waveform *_wave
	const char *_encoding

swift_result_t
swift_waveform_set_channels(_wave, _channels)
	swift_waveform *_wave
	int _channels

void
swift_waveform_close(_wave)
	swift_waveform *_wave

void
swift_waveform_get_samples(_wave)
		swift_waveform *_wave
	INIT:
		int16_t *buffer = NULL;
		int samples = 0;
		int bytes_per_sample = 0;
		int i = 0;

	PPCODE:
		if (SWIFT_FAILED(swift_waveform_get_samples(_wave, (const void**)&buffer, &samples, &bytes_per_sample)))
		{
			croak("failed to get samples from waveform object");
		}

		if ( (samples > 0) && (bytes_per_sample > 0) )
		{
			for(i=0; i<samples; i++)
			{
				XPUSHs(sv_2mortal(newSVnv(buffer[i])));
			}
		} else
		{
			croak("invalid waveform: samples=%d, bytes_per_sample=%d", samples, bytes_per_sample);
		}
