// Relocate.cpp : Defines the Relocate custom action.
//
// Copyright (c) Curtis Jewell 2009, 2010
//
// This code is free software; you can redistribute it and/or modify it
// under the same terms as Perl itself.

#include "stdafx.h"

// Helper macros for error checking.

#define MSI_OK(x) \
	if (ERROR_SUCCESS != x) { \
		return x; \
	}
 
#define MSI_OK_FREE(x, y) \
	if (ERROR_SUCCESS != x) { \
		free(y); \
		return x; \
	}

#define MSI_OK_FREE_2(x, y, z) \
	if (ERROR_SUCCESS != x) { \
		free(y); \
		free(z); \
		return x; \
	}

#define HANDLE_OK(x) \
	if (NULL == x) { \
		return ERROR_INSTALL_FAILURE; \
	}

UINT _stdcall Relocate_MoveFile(
	const TCHAR *sFileTo,   // Original name of the file 
	const TCHAR *sFileFrom) // File to rename into its place.
{
	// Create "to-the-side" location for original file.
	TCHAR sFileSpec[_MAX_PATH];
	_tcscpy_s(sFileSpec, _MAX_PATH, sFileTo);
	_tcscat_s(sFileSpec, _MAX_PATH, _T(".old"));

	BOOL bAnswer = TRUE;

	// Move original file out of the way.
	bAnswer = ::MoveFileEx(sFileTo, sFileSpec, MOVEFILE_WRITE_THROUGH);
	if (bAnswer == FALSE)
		return ERROR_INSTALL_FAILURE;

	// Move new file into the old file's place.
	bAnswer = ::MoveFileEx(sFileFrom, sFileTo, MOVEFILE_WRITE_THROUGH);
	if (bAnswer == FALSE)
		return ERROR_INSTALL_FAILURE;

	// Remove the old file.
	bAnswer = ::DeleteFile(sFileSpec);
	if (bAnswer == FALSE)
		return ERROR_INSTALL_FAILURE;

	return ERROR_SUCCESS;
}



void _stdcall Relocate_GetSearchString(
		  TCHAR *sString,   // String to search for [out] 
	const TCHAR *sDir,      // Directory to search for.
	const TCHAR *sType)     // Type of search to do.
{
	if (0 == _tcscmp(sType, _T("backslash"))) {
		_tcscpy_s(sString, _MAX_PATH, sDir);
		return;
	}

	TCHAR *sWorkP = NULL;
	if (0 == _tcscmp(sType, _T("slash"))) {
		_tcscpy_s(sString, _MAX_PATH, sDir);

		// Change each backslash to a slash.
		sWorkP = _tcschr(sString, _T('\\'));
		while(sWorkP) {
			*sWorkP = _T('/');
			sWorkP = _tcschr(sString, _T('\\'));
		}

		return;
	}

	if (0 == _tcscmp(sType, _T("doublebackslash"))) {
		TCHAR *sWork1 = (TCHAR *)malloc((_MAX_PATH + 1) * sizeof(TCHAR));
		TCHAR *sWork2 = (TCHAR *)malloc((_MAX_PATH + 1) * sizeof(TCHAR));

		_tcscpy_s(sString, _MAX_PATH, sDir);

		// Change to slashes first.
		sWorkP = _tcschr(sString, _T('\\'));
		while(sWorkP) {
			*sWorkP = _T('/');
			sWorkP = _tcschr(sString, _T('\\'));
		}

		_tcscpy_s(sWork1, _MAX_PATH, sString);
		sWorkP = _tcschr(sWork1, _T('/'));
		while (sWorkP) {
			// Fix to make sure that we don't attempt to buffer-overrun.
			if (1 == _tcslen(sWorkP)) {
				// Add the second slash.
				_tcscat_s(sWork1, _MAX_PATH, _T("\\"));

				// Set the first one.
				*sWorkP = _T('\\');

				// We're done.
				break;
			}

			// Block it to copying before the slash.
			*sWorkP = _T('\0');
			_tcscpy_s(sWork2, _MAX_PATH, sWork1);

			// Append the backslashes, and then the rest of the string.
			_tcscat_s(sWork2, _MAX_PATH, _T("\\\\"));
			_tcscat_s(sWork2, _MAX_PATH, ++sWorkP);

			// Copy back out of our work area, so that they match.
			_tcscpy_s(sWork1,  _MAX_PATH, sWork2);

			// Try another search.
			sWorkP = _tcschr(sWork1, _T('/'));
		}

		// Copy our answer out.
		_tcscpy_s(sString, _MAX_PATH, sWork1);
		free((void*)sWork1);
		free((void*)sWork2);
		return;
	}

	if (0 == _tcscmp(sType, _T("url"))) {
		TCHAR sWork3[_MAX_PATH + 1];
		_tcscpy_s(sWork3, _MAX_PATH, sDir);

		// Change each backslash to a slash.
		sWorkP = _tcschr(sWork3, _T('\\'));
		while(sWorkP) {
			*sWorkP = _T('/');
			sWorkP = _tcschr(sWork3, _T('\\'));
		}

		_tcscpy_s(sString, _MAX_PATH, _T("file:///"));
		_tcscat_s(sString, _MAX_PATH, sWork3);
		return;
	}

	// Error: Return an empty string.
	_tcscpy_s(sString, _MAX_PATH, _T(""));
	return;

}

// The string to be logged to Windows Installer.
static TCHAR sLogStringR[513];

// Operations on string to log to MSI log.

void StartLogStringR(
	LPCTSTR s) // String to start logging. [in]
{
	_tcscpy_s(sLogStringR, 512, s);
}

void AppendLogStringR(
	LPCTSTR s) // String to append to log. [in]
{
	_tcscat_s(sLogStringR, 512, s);
}

/* All routines after this point return UINT error codes,
 * as defined by the Win32 API reference under the Installer Functions
 * area (at http://msdn.microsoft.com/en-us/library/aa369426(VS.85).aspx ) 
 */

// Logs string in MSI log.

UINT LogStringR(
	MSIHANDLE hModule) // Handle of MSI being installed. [in]
{
	// Set up variables.
	PMSIHANDLE hRecord = ::MsiCreateRecord(2);
    HANDLE_OK(hRecord)

	UINT uiAnswer = ::MsiRecordSetString(hRecord, 0, sLogStringR);
	MSI_OK(uiAnswer)
	
	// Send the message
	uiAnswer = ::MsiProcessMessage(hModule, INSTALLMESSAGE(INSTALLMESSAGE_INFO), hRecord);

	// Corrects return value for use with MSI_OK.
	switch (uiAnswer) {
	case IDOK:
	case 0: // Means no action was taken...
		return ERROR_SUCCESS;
	case IDCANCEL:
		return ERROR_INSTALL_USEREXIT;
	default:
		return ERROR_INSTALL_FAILURE;
	}
}


UINT Blip(
	MSIHANDLE hModule) // Handle of MSI being installed. [in]
{
	// Set up variables.
	PMSIHANDLE hRecord = ::MsiCreateRecord(4);
    HANDLE_OK(hRecord)

	UINT uiAnswer = ::MsiRecordSetInteger(hRecord, 1, 2);
	MSI_OK(uiAnswer)
	
	uiAnswer = ::MsiRecordSetInteger(hRecord, 2, 0);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetInteger(hRecord, 3, 0);
	MSI_OK(uiAnswer)

	uiAnswer = ::MsiRecordSetInteger(hRecord, 4, 0);
	MSI_OK(uiAnswer)

	// Send the message
	uiAnswer = ::MsiProcessMessage(hModule, INSTALLMESSAGE(INSTALLMESSAGE_PROGRESS), hRecord);

	// Corrects return value for use with MSI_OK.
	switch (uiAnswer) {
	case IDOK:
	case 0: // Means no action was taken...
		return ERROR_SUCCESS;
	case IDCANCEL:
		return ERROR_INSTALL_USEREXIT;
	default:
		return ERROR_INSTALL_FAILURE;
	}
}


UINT _stdcall Relocate_File(
	MSIHANDLE hModule,
	const TCHAR *sDirectoryFrom, // Directory to relocate from
	const TCHAR *sDirectoryTo,   // Directory to relocate to
	const TCHAR *sFile,          // File to relocate
	const TCHAR *sType)          // Type of relocation to do.
{
	UINT uiAnswer = ERROR_SUCCESS;
	TCHAR sFileIn[_MAX_PATH];
	TCHAR sFileOut[_MAX_PATH];
	_tcscpy_s(sFileIn, _MAX_PATH, sDirectoryTo);
	_tcscat_s(sFileIn, _MAX_PATH, sFile);
	_tcscpy_s(sFileOut, _MAX_PATH, sFileIn);
	_tcscat_s(sFileOut, _MAX_PATH, _T(".new"));

	TCHAR sStringIn[_MAX_PATH];
	TCHAR sStringOut[_MAX_PATH];

	// Log the fact that we're relocating a file.
	StartLogStringR(_T("Relocating "));
	AppendLogStringR(sFile);
	AppendLogStringR(_T(" using relocation type "));
	AppendLogStringR(sType);
	uiAnswer = LogStringR(hModule);
	MSI_OK(uiAnswer)

	// Get the strings to look for.
	Relocate_GetSearchString(sStringIn,  sDirectoryFrom, sType);
	Relocate_GetSearchString(sStringOut, sDirectoryTo,   sType);

	if (0 == _tcscmp(sStringIn, _T(""))) {
		return ERROR_INSTALL_FAILURE;
	}

	if (0 == _tcscmp(sStringOut, _T(""))) {
		return ERROR_INSTALL_FAILURE;
	}

	// Open our files.
	FILE *fFileIn;
	FILE *fFileOut;
	errno_t eAnswer = 0;
	eAnswer = _tfopen_s(&fFileIn, sFileIn, _T("rtS"));
	if (eAnswer != 0) {
		return ERROR_INSTALL_FAILURE;
	}
	eAnswer = _tfopen_s(&fFileOut, sFileOut, _T("wt"));
	if (eAnswer != 0) {
		fclose(fFileIn);
		return ERROR_INSTALL_FAILURE;
	}

	// Set up our variables for the relocation.
	TCHAR  sLine[32767];
	TCHAR  sWork1[32767];
	TCHAR  sWork2[32767];
	TCHAR *sLoc   = NULL;
	size_t iStringInLength = _tcslen(sStringIn);
	size_t iStringOutLength = _tcslen(sStringOut);
	int iErrorFlag = 0;
	long lLine = 0;
	// Do the relocation.
	while (!feof(fFileIn)) {

		// Deal with errors. 
		if( _fgetts( sLine, 32766, fFileIn ) == NULL) {
			if (iErrorFlag) {
				fclose(fFileIn);
				fclose(fFileOut);
				::DeleteFile(sFileOut);
				uiAnswer = ERROR_INSTALL_FAILURE;
				break;
			}
			iErrorFlag++;
			continue;
		}

		_tcscpy_s(sWork1, 32766, sLine);
		sLoc = _tcsstr(sWork1, sStringIn);
		while (sLoc) {
			// "Cap" the initial string and copy it to sWork2, then append sStringOut to it.
			*sLoc = _T('\0');
			_tcscpy_s(sWork2, 32766, sWork1);
			_tcscat_s(sWork2, 32766, sStringOut);

			// Append the rest of the line.
			sLoc += iStringInLength;
			_tcscat_s(sWork2, 32766, sLoc);

			// Copy back out of our work area, so that they match.
			_tcscpy_s(sWork1, 32766, sWork2);

			// Advance along the string.
			sLoc -= iStringInLength;
			sLoc += iStringInLength;

			// Try another search.
			sLoc = _tcsstr(sLoc, sStringIn);

			// If we're done, copy to sLine so it can be written out.
			if (!sLoc) {
				_tcscpy_s(sLine, 32766, sWork1);
			}
		}
		
		// Write the line out.
		_fputts(sLine, fFileOut);

		// Check every so often for cancel button.
		lLine++;
		if (0 == (lLine % 100)) {
			uiAnswer = Blip(hModule);
			if (ERROR_SUCCESS != uiAnswer) {
				fclose(fFileIn);
				fclose(fFileOut);
				::DeleteFile(sFileOut);
				return uiAnswer;
			}
		}

	}

	fflush(fFileOut);
	fclose(fFileIn);
	fclose(fFileOut);

	MSI_OK(uiAnswer);

	BOOL bAnswer = TRUE;
	// Check for readonly status on the file.
	DWORD dwAttributes = ::GetFileAttributes(sFileIn);
	if (dwAttributes && FILE_ATTRIBUTE_READONLY) {
		bAnswer = ::SetFileAttributes(sFileIn, dwAttributes && !FILE_ATTRIBUTE_READONLY);
		if (bAnswer == FALSE) { 
			::DeleteFile(sFileOut);
			uiAnswer = ERROR_INSTALL_FAILURE; 
		}
		MSI_OK(uiAnswer)
	}

	uiAnswer = Relocate_MoveFile(sFileIn, sFileOut);
	MSI_OK(uiAnswer)

	// Set readonly status back.
	if (dwAttributes && FILE_ATTRIBUTE_READONLY) {
		::SetFileAttributes(sFileIn, dwAttributes);
	}

	return uiAnswer;
}


UINT __stdcall Relocate_Worker(
	MSIHANDLE hModule,				// Handle of MSI being installed. [in]
									// Passed to most other routines.
	const TCHAR *sInstallDirectory,	// Directory being installed into.
	const TCHAR *sRelocationFile)	// File to use to relocate.
{
	UINT uiAnswer;
	FILE *fRelocationFileIn;
	FILE *fRelocationFileOut;
	TCHAR sLine[_MAX_PATH + 12];
	TCHAR sFileFrom[_MAX_PATH + 1];
	TCHAR sFileTo[_MAX_PATH + 1];
	TCHAR sDirectoryFrom[_MAX_PATH + 1];
	TCHAR sDirectoryTo[_MAX_PATH + 1];

	// Get filename to open
	_tcscpy_s(sFileFrom, _MAX_PATH, sRelocationFile);
	_tcscpy_s(sFileTo, _MAX_PATH, sRelocationFile);
	_tcscat_s(sFileTo, _MAX_PATH, _T(".new"));

	// Log what we're doing.
	StartLogStringR(_T("Opening "));
	AppendLogStringR(sFileFrom);
	uiAnswer = LogStringR(hModule);
	MSI_OK(uiAnswer)
	StartLogStringR(_T("Relocating to "));
	AppendLogStringR(sInstallDirectory);
	uiAnswer = LogStringR(hModule);
	MSI_OK(uiAnswer)

	// Open our files.
	errno_t eAnswer = 0;
	eAnswer = _tfopen_s(&fRelocationFileIn, sFileFrom, _T("rtS"));
	if (eAnswer != 0) 
		return ERROR_INSTALL_FAILURE;

	// First line of relocation file has where to relocate from.
	if( _fgetts( sDirectoryFrom, _MAX_PATH + 1, fRelocationFileIn ) == NULL) {
		fclose(fRelocationFileIn);
		return ERROR_INSTALL_FAILURE;
	}

	// Take off the line ending.
	*(sDirectoryFrom + _tcslen(sDirectoryFrom) - 1) = _T('\0');

	// Second parameter is where to relocate to.
	_tcscpy_s(sDirectoryTo, _MAX_PATH, sInstallDirectory);

	// Make sire it ends in a slash.
	if (*(sDirectoryTo + _tcslen(sDirectoryTo) - 1) != _T('\\')) {
		_tcscat_s(sDirectoryTo, _MAX_PATH, _T("\\"));
	}

	// We don't need to relocate if the directories are identical, right? right.
	// It's not an error, however.
	if (0 == _tcscmp(sDirectoryFrom, sDirectoryTo)) {
		fclose(fRelocationFileIn);
		return ERROR_SUCCESS;
	}

	// Open up the file to write relocating to.
	eAnswer = _tfopen_s(&fRelocationFileOut, sFileTo, _T("wt"));
	if (eAnswer != 0) {
		fclose(fRelocationFileIn);
		return ERROR_INSTALL_FAILURE;
	}

	// Log what we're doing.
	StartLogStringR(_T("Relocating from "));
	AppendLogStringR(sDirectoryFrom);
	uiAnswer = LogStringR(hModule);
	MSI_OK(uiAnswer)

	// Put where to relocate to in the file.
	_fputts(sDirectoryTo, fRelocationFileOut);
	_fputts(_T("\n"), fRelocationFileOut);

	int iErrorFlag = 0;
	// Go into the relocation loop.
	while (!feof(fRelocationFileIn)) {

		// Deal with errors. 
		if( _fgetts( sLine, _MAX_PATH + 11, fRelocationFileIn ) == NULL) {
			if (iErrorFlag) {
				uiAnswer = ERROR_INSTALL_FAILURE;
				break;
			}
			iErrorFlag++;
			continue;
		}

		// Deal with comments.
		if ('#' == *sLine) {
			_fputts(sLine, fRelocationFileOut);
			continue;
		}

		// Deal with lines that contain only whitespace.
		if (_tcslen(sLine) <= _tcsspn(sLine, _T(" \t\n")))
			continue;

		// Check for the colon.
		if (NULL == _tcschr(sLine, _T(':')))
			continue;

		// We have a good line. So put it back out before we tokenize it.
		_fputts(sLine, fRelocationFileOut);

		// Take off the line ending for tokenizing purposes.
		*(sLine + _tcslen(sLine) - 1) = _T('\0');

		// Tokenize the line.
		TCHAR  sFileToRelocate[_MAX_PATH + 1];
		TCHAR  sRelocationType[17];
		TCHAR *sTokenContext = NULL;
		TCHAR *sToken = NULL;

		sToken = _tcstok_s(sLine, _T(":"), &sTokenContext);
		_tcscpy_s(sFileToRelocate, _MAX_PATH, sToken);
		sToken = _tcstok_s(NULL, _T("\n"), &sTokenContext);
		_tcscpy_s(sRelocationType, 16, sToken);

		// Actually relocate the file.
		uiAnswer = Relocate_File(hModule, sDirectoryFrom, sDirectoryTo, sFileToRelocate, sRelocationType);
		if (uiAnswer != ERROR_SUCCESS) {
			break;
		}
	}

	fflush(fRelocationFileOut);
	fclose(fRelocationFileIn);
	fclose(fRelocationFileOut);

	MSI_OK(uiAnswer);

	uiAnswer = Relocate_MoveFile(sFileFrom, sFileTo);
	return uiAnswer;
}



UINT __stdcall RelocateMM(
	MSIHANDLE hModule) // Handle of MSI being installed. [in]
	                   // Passed to most other routines.
{
	TCHAR sInstallDirectory[MAX_PATH + 1];
	TCHAR sRelocationFile[MAX_PATH + 1];
	TCHAR sCAData[MAX_PATH * 2 + 6];
	UINT uiAnswer;
	DWORD dwPropLength;

	// Get directory to relocate to.
	dwPropLength = MAX_PATH * 2 + 5; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("CustomActionData"), sCAData, &dwPropLength); 
	MSI_OK(uiAnswer)

	TCHAR *sTokenContext = NULL;
	TCHAR *sToken = NULL;

	sToken = _tcstok_s(sCAData, _T(";"), &sTokenContext);
	if (0 != _tcscmp(sToken, _T("MM"))) {
		return ERROR_INSTALL_FAILURE;
	}
	sToken = _tcstok_s(NULL, _T(";"), &sTokenContext);
	_tcscpy_s(sInstallDirectory, _MAX_PATH, sToken);
	sToken = _tcstok_s(NULL, _T(";"), &sTokenContext);
	_tcscpy_s(sRelocationFile, _MAX_PATH, sToken);


	return Relocate_Worker(hModule, sInstallDirectory, sRelocationFile);

}


UINT __stdcall Relocate(
	MSIHANDLE hModule) // Handle of MSI being installed. [in]
	                   // Passed to most other routines.
{
	TCHAR sInstallDirectory[MAX_PATH + 1];
	TCHAR sRelocationFile[MAX_PATH + 1];
	TCHAR sCAData[MAX_PATH * 2 + 7];
	UINT uiAnswer;
	DWORD dwPropLength;

	// Get directory to relocate to.
	dwPropLength = MAX_PATH * 2 + 6; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("CustomActionData"), sCAData, &dwPropLength); 
	MSI_OK(uiAnswer)

	TCHAR *sTokenContext = NULL;
	TCHAR *sToken = NULL;

	sToken = _tcstok_s(sCAData, _T(";"), &sTokenContext);
	if (0 != _tcscmp(sToken, _T("MSI"))) {
		return ERROR_INSTALL_FAILURE;
	}
	sToken = _tcstok_s(NULL, _T(";"), &sTokenContext);
	_tcscpy_s(sInstallDirectory, _MAX_PATH, sToken);
	sToken = _tcstok_s(NULL, _T(";"), &sTokenContext);
	_tcscpy_s(sRelocationFile, _MAX_PATH, sToken);

	return Relocate_Worker(hModule, sInstallDirectory, sRelocationFile);

}



