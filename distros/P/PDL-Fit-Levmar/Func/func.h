void _open_and_find (  char * lib_name, char * func_name, void ** lib_handle ,
		       void ** func_pointer, char * error_message, int nchar );
void _close_shared_object_file( void ** lib_handle, int * rval, char * error_message, int nchar );
