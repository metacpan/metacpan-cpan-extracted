MODULE = PDL::Audio PACKAGE = PDL::Audio

# additional XS parts for PDL::Audio

int
initialize_sndlib ()

int
sound_samples(arg)
	char *	arg

int
sound_frames (arg)
	char *	arg

float
sound_duration (arg)
	char *	arg

int
sound_datum_size (arg)
	char *	arg

int
sound_data_location (arg)
	char *	arg

int
sound_chans (arg)
	char *	arg

int
sound_srate (arg)
	char *	arg

int
sound_header_type (arg)
	char *	arg

int
sound_data_format (arg)
	char *	arg

int
sound_original_format (arg)
	char *	arg

char *
sound_comment (arg)
	char *	arg

int
sound_comment_start (arg)
	char *	arg

int
sound_comment_end (arg)
	char *	arg

int
sound_length (arg)
	char *	arg

int
sound_fact_samples (arg)
	char *	arg

int
sound_distributed (arg)
	char *	arg

int
sound_write_date (arg)
	char *	arg

int
sound_type_specifier (arg)
	char *	arg

int
sound_align (arg)
	char *	arg

int
sound_bits_per_sample(arg)
	char *	arg

int
sound_aiff_p(arg)
	char *	arg

int
sound_bytes_per_sample(format)
	int	format

#int
#sound_max_amp(arg, vals)
#	char *	arg
#	int *	vals

char *
sound_type_name(type)
	int	type

char *
sound_format_name(format)
	int	format


int
open_sound_input (path)
	char *	path

int
open_sound_output (path, srate, chans, format, filetype, comment)
    	char *	path
        int	srate
        int	chans
        int	format
        int	filetype
        char *	comment

int
close_sound_input (fd)
	int	fd

int
close_sound_output (fd, bytes_of_data)
	int	fd
        int	bytes_of_data

void
mus_set_raw_header_defaults (srate, chans, format)
	int	srate
        int	chans
        int	format

int
mus_format2bytes (format)
	int	format

int
mus_samples2bytes (format, size)
	int	format
        int	size

int
mus_bytes2samples (format, size)
	int	format
        int	size

#int
#read_sound (fd, beg, end, chans, int fd, int beg, int end, int chans, int **bufs) 
#
#int
#write_sound (int fd, int beg, int end, int chans, int **bufs) 

char *
audio_error_name (err)
	int	err

int
audio_error ()

# MUS MODULE

#void
#init_mus_module ()



