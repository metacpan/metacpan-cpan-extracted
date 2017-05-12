HV*
hash_ppd_option_t( ppd_option_t* option )
{
		HV* hv;
		HV* choice;
		AV* choices;
		int loop;

		if( option != NULL )
		{
		        hv = newHV();

			hv_store( hv, "conflicted", 
					  strlen( "conflicted" ),
					  newSViv( option->conflicted ), 0 );

			hv_store( hv, "keyword", 
					  strlen( "keyword" ),
					  newSVpv( option->keyword, PPD_MAX_NAME ), 0 );

			hv_store( hv, "defchoice", 
					  strlen( "defchoice" ),
					  newSVpv( option->defchoice, PPD_MAX_NAME ), 0 );

			hv_store( hv, "text", 
					  strlen( "text" ),
					  newSVpv( option->text, PPD_MAX_TEXT ), 0 );

			hv_store( hv, "ui", 
					  strlen( "ui" ),
					  newSViv( option->ui ), 0 );

			hv_store( hv, "section", 
					  strlen( "section" ),
					  newSViv( option->section ), 0 );

			hv_store( hv, "order", 
					  strlen( "order" ),
					  newSViv( option->order ), 0 );

			hv_store( hv, "num_choices", 
					  strlen( "num_choices" ),
					  newSViv( option->num_choices ), 0 );

			choices = newAV();

			hv_store( hv, "choices",
					  strlen( "choices" ),
					  newSVsv( newRV( (SV*)choices ) ), 0 );

			for( loop = 0; loop < option->num_choices; loop++ )
			{
				choice = newHV();

				hv_store( choice, "marked", 
						  strlen( "marked" ),
						  newSViv( option->choices[loop].marked ), 0 );

				hv_store( choice, "choice", 
						  strlen( "choice" ),
						  newSVpv( option->choices[loop].choice, 
								   PPD_MAX_NAME ), 0 );

				hv_store( choice, "text", 
						  strlen( "text" ),
						  newSVpv( option->choices[loop].text, 
								   PPD_MAX_TEXT ), 0 );

				if(option->choices[loop].code != NULL)
					hv_store( choice, "code",
					    strlen( "code" ),
					    newSVpv( option->choices[loop].code,
						     strlen( option->choices[loop].code ) ), 0 );

				av_push( choices, newRV( (SV*)choice ) );
			}
			return( hv );
		
		} else {
			return(NULL);
		}
}

// vim: noet sts=8 sw=8
