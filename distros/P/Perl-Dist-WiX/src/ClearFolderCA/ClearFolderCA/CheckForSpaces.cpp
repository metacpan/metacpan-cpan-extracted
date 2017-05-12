// CheckForSpaces.cpp : Defines the CheckForSpaces custom action.
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

UINT __stdcall CheckForSpaces(
	MSIHANDLE hModule) // Handle of MSI being installed. [in]
	                   // Passed to most other routines.
{
	TCHAR sInstallDir[MAX_PATH + 1];
	TCHAR sNum[11];
	DWORD dwPropLength;
	UINT uiAnswer;

	// Get directory to search.
	dwPropLength = 10; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("WIXUI_INSTALLDIR_VALID"), sNum, &dwPropLength); 
	if (ERROR_MORE_DATA == uiAnswer) {
		uiAnswer = ERROR_SUCCESS;
	}
	MSI_OK(uiAnswer)

	if (0 != _tcscmp(sNum, _T("1"))) {
		return ERROR_SUCCESS;
	}

	// Get directory to check.
	dwPropLength = MAX_PATH; 
	uiAnswer = ::MsiGetProperty(hModule, TEXT("INSTALLDIR"), sInstallDir, &dwPropLength); 
	MSI_OK(uiAnswer)

	if (NULL != _tcsspnp(sInstallDir, 
		_T("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&'()+,-.;=@[]^_`{}~:\\"))) {
		return ::MsiSetProperty(hModule, TEXT("WIXUI_INSTALLDIR_VALID"), TEXT("-2"));
	}

	// Check the "long name" of that directory.
	TCHAR sInstallDirWork[MAX_PATH + 1];
	TCHAR sInstallDirLong[MAX_PATH + 1];
	_tcscpy_s(sInstallDirWork, MAX_PATH, sInstallDir);
	DWORD dwAnswer = ::GetLongPathName(sInstallDirWork, sInstallDirLong, MAX_PATH);

	TCHAR* pcSlash;
	DWORD dwError;
	while (0 == dwAnswer) {

		dwError = ::GetLastError();
		if ((ERROR_FILE_NOT_FOUND != dwError) && (ERROR_PATH_NOT_FOUND != dwError))
			break;

		// Keep working backwards until we get it right, or until there are no more backslashes.
		pcSlash = _tcsrchr(sInstallDirWork, _T('\\'));
		if (NULL == pcSlash) 
			break;

		*pcSlash = _T('\0');
		dwAnswer = ::GetLongPathName(sInstallDirWork, sInstallDirLong, MAX_PATH);
	}

	if (NULL != _tcsspnp(sInstallDirLong, 
		_T("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz!#$%&'()+,-.;=@[]^_`{}~:\\"))) {
		return ::MsiSetProperty(hModule, TEXT("WIXUI_INSTALLDIR_VALID"), TEXT("-2"));
	}

	return ::MsiSetProperty(hModule, TEXT("WIXUI_INSTALLDIR_VALID"), TEXT("1"));
}
