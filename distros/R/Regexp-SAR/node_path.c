

sarNode_p sar_buildNode_c() {
    sarNode_p newNode;
    Newx(newNode, 1, sarNode_t);

    char * nodeChars;
    sarNode_p *nodes;
    newNode->charNumber = 0;
    newNode->sarNodes = nodes;
    newNode->sarPathChars = nodeChars;
    newNode->plusNode = (sarNode_p)NULL;
    newNode->digitNode = (sarNode_p)NULL;
    newNode->alphaNumNode = (sarNode_p)NULL;
    newNode->alphaNode = (sarNode_p)NULL;
    newNode->dotNode = (sarNode_p)NULL;
    newNode->spaceNode = (sarNode_p)NULL;
    newNode->negativeNode = (sarNode_p)NULL;

    Newx(newNode->callFunc, 1, SV*);
    newNode->callFunc[0] = (SV*)NULL;
    newNode->getCallFunc = SAR_FALSE;
    return newNode;
}

sarRootNode_p sar_buildRootNode_c() {
    sarRootNode_p newNode;
    Newx(newNode, 1, sarRootNode_t);

    newNode->sarNode = sar_buildNode_c();
    newNode->procFlags = 0;
    return newNode;
}

void sar_cleanAll_c(sarNode_p node) {
	if (node == (sarNode_p)NULL) {
		return;
	}

	int charNumber = node->charNumber;
	if (charNumber > 0) {
	  int i;
	  for(i=0; i<charNumber; ++i) {
		sar_cleanAll_c(node->sarNodes[i]);
	  }
	}

	Safefree(node->sarPathChars);
	Safefree(node->sarNodes);

	int currCallIdx = 0;
	while ( node->callFunc[currCallIdx] != (SV*)NULL ) {
		SvREFCNT_dec(node->callFunc[currCallIdx]);
		++currCallIdx;
	}
	Safefree(node->callFunc);

	sar_cleanAll_c(node->plusNode);
	sar_cleanAll_c(node->digitNode);
	sar_cleanAll_c(node->alphaNumNode);
	sar_cleanAll_c(node->alphaNode);
	sar_cleanAll_c(node->dotNode);
	sar_cleanAll_c(node->spaceNode);
	sar_cleanAll_c(node->negativeNode);

	Safefree(node);

}


void sar_nodeAddCharNode_c(sarNode_p node, sarNode_p newNode, char newChar) {
    int currSize = node->charNumber;

    int newSize = currSize+1;
    Renew(node->sarPathChars, newSize, char);
    Renew(node->sarNodes, newSize, sarNode_p);
    node->charNumber = newSize;

    int charOffset = 0;
    while(charOffset < currSize) {
        if (newChar < node->sarPathChars[charOffset]) {
            break;
        }
        ++charOffset;
    }

    int cpOffset = currSize;
    while(cpOffset > charOffset) {
        node->sarPathChars[cpOffset] = node->sarPathChars[cpOffset - 1];
        node->sarNodes[cpOffset] = node->sarNodes[cpOffset - 1];
        --cpOffset;
    }

    node->sarPathChars[cpOffset] = newChar;
    node->sarNodes[cpOffset] = newNode;
}



int sar_searchChar_c(const char * chars, int charsSize, char pathChar) {
    int imax = charsSize - 1;
    int imin = 0;

    while (imax >= imin) {
        int imid = (imin + imax) >> 1;
        char checkChar = chars[imid];
        if (pathChar < checkChar) {
            imax = imid - 1;
        }
        else if (pathChar > checkChar) {
            imin = imid + 1;
        }
        else {
            return imid;
        }
    }

    return -1;
}



sarNode_p sar_nodeAddClass_c(sarNode_p currNode, char pathChar, sar_nodeClass nodeClass) {
	sarNode_p childNode;
	if (nodeClass == SAR_DIGIT) {
		if (currNode->digitNode == (sarNode_p)NULL) {
			currNode->digitNode = sar_buildNode_c();
		}
		childNode = currNode->digitNode;
	}
	else if (nodeClass == SAR_ALPHA_NUM) {
		if (currNode->alphaNumNode == (sarNode_p)NULL) {
			currNode->alphaNumNode = sar_buildNode_c();
		}
		childNode = currNode->alphaNumNode;
	}
	else if (nodeClass == SAR_ALPHA) {
		if (currNode->alphaNode == (sarNode_p)NULL) {
			currNode->alphaNode = sar_buildNode_c();
		}
		childNode = currNode->alphaNode;
	}
	else if (nodeClass == SAR_SPACE) {
		if (currNode->spaceNode == (sarNode_p)NULL) {
			currNode->spaceNode = sar_buildNode_c();
		}
		childNode = currNode->spaceNode;
	}
	else if (nodeClass == SAR_DOT) {
		if (currNode->dotNode == (sarNode_p)NULL) {
			currNode->dotNode = sar_buildNode_c();
		}
		childNode = currNode->dotNode;
	}
	else {
	    int existNodePos = sar_searchChar_c(currNode->sarPathChars, currNode->charNumber, pathChar);
	    if (existNodePos >= 0 ) {
	    	childNode = currNode->sarNodes[existNodePos];
	    }
	    else {
	    	sarNode_p newNode = sar_buildNode_c();
	    	newNode->pathChar = pathChar;
	    	sar_nodeAddCharNode_c(currNode, newNode, pathChar);
	    	childNode = newNode;
	    }
	}

	return childNode;
}


sarNode_p sar_nodeAddPlus_c(sarNode_p currNode, char pathChar, sar_nodeClass nodeClass) {
	if (currNode->plusNode == (sarNode_p)NULL) {
		sarNode_p newNode = sar_buildNode_c();
	    newNode->pathChar = pathChar;
		currNode->plusNode = newNode;
	}

	sarNode_p plusNode = currNode->plusNode;
	return sar_nodeAddClass_c(plusNode, pathChar, nodeClass);
}





void sar_setCallFunc_c(sarNode_p currNode, SV * callFunc) {
    int funcArrSize = 0;
    while ( currNode->callFunc[funcArrSize] != (SV*)NULL ) {
        ++funcArrSize;
    }
    Renew(currNode->callFunc, funcArrSize+2, SV*);
    currNode->callFunc[funcArrSize] = newSVsv(callFunc);
    ++funcArrSize;
    currNode->callFunc[funcArrSize] = (SV*)NULL;
}


sarNodeWithFuncLL_p sar_addNodeFunc_c (sarNode_p currNode, SV * callFunc, sarNodeWithFuncLL_p nwf) {
	if (SAR_FALSE == currNode->getCallFunc) {
		currNode->getCallFunc = SAR_TRUE;
		nwf = sar_addNWF_c(nwf, currNode);
		sar_setCallFunc_c(currNode, callFunc);
	}

	return nwf;
}


sarNodeWithFuncLL_p sar_buildNodePath_c(sarNode_p currNode, const char * regexp, int currPos, int len, SV * callFunc, sarNodeWithFuncLL_p nwf, sar_bool negative) {

	if (currPos >= len) {
		return sar_addNodeFunc_c(currNode, callFunc, nwf);
	}

	sarNode_p negativeNode = (sarNode_p)NULL;
	if (negative) {
		if (currNode->negativeNode == (sarNode_p)NULL) {
			currNode->negativeNode = sar_buildNode_c();
		}
		negativeNode = currNode->negativeNode;
	}

    char pathChar = regexp[currPos];
    int nextPos = currPos + 1;
    sar_nodeClass nodeClass = SAR_NOCLASS;
    if (pathChar == '\\') {
    	if (nextPos >= len) {
    		return sar_addNodeFunc_c(currNode, callFunc, nwf);
    	}

    	char nextChar = regexp[nextPos];

    	if (nextChar == '^') {
    	    nwf = sar_buildNodePath_c(currNode, regexp, currPos+2, len, callFunc, nwf, SAR_TRUE);
    		return nwf;
    	}

    	if (nextChar == 's') {
    		nodeClass = SAR_SPACE;
    		currPos = nextPos;
    		nextPos = nextPos + 1;
    	}
    	else if (nextChar == 'd') {
    		nodeClass = SAR_DIGIT;
    		currPos = nextPos;
    		nextPos = nextPos + 1;
    	}
    	else if (nextChar == 'w') {
    		nodeClass = SAR_ALPHA_NUM;
    		currPos = nextPos;
    		nextPos = nextPos + 1;
    	}
    	else if (nextChar == 'a') {
    		nodeClass = SAR_ALPHA;
    		currPos = nextPos;
    		nextPos = nextPos + 1;
    	}
    	else if (nextChar == '\\') {
    		currPos = nextPos;
    		nextPos = nextPos + 1;
    	}
    	else {
    	    nwf = sar_buildNodePath_c(currNode, regexp, currPos+1, len, callFunc, nwf, SAR_FALSE);
    		return nwf;
    	}
    }
    else {
    	if (pathChar == '.' && ! (currPos > 0 && regexp[currPos-1] == '\\')) {
    		nodeClass = SAR_DOT;
    	}
    }

    if (nextPos < len ) {
    	char nextChar = regexp[nextPos];
    	if (nextChar == '?') {
    		nwf = sar_buildNodePath_c(currNode, regexp, currPos+2, len, callFunc, nwf, SAR_FALSE);
    		if (negative) {
    			currNode = negativeNode;
    		}
    	    sarNode_p childNode = sar_nodeAddClass_c(currNode, pathChar, nodeClass);
    		nwf = sar_buildNodePath_c(childNode, regexp, currPos+2, len, callFunc, nwf, SAR_FALSE);
    		return nwf;
		}
    	else if (nextChar == '+') {
    		if (negative) {
    			currNode = negativeNode;
    		}
    		sarNode_p childNode = sar_nodeAddPlus_c(currNode, pathChar, nodeClass);
    		nwf = sar_buildNodePath_c(childNode, regexp, currPos+2, len, callFunc, nwf, SAR_FALSE);
    		return nwf;
    	}
    	else if (nextChar == '*') {
    		nwf = sar_buildNodePath_c(currNode, regexp, currPos+2, len, callFunc, nwf, SAR_FALSE);
    		if (negative) {
    			currNode = negativeNode;
    		}
    	    sarNode_p childNode = sar_nodeAddPlus_c(currNode, pathChar, nodeClass);
    		nwf = sar_buildNodePath_c(childNode, regexp, currPos+2, len, callFunc, nwf, SAR_FALSE);
    		return nwf;
    	}
    }


	if (negative) {
		currNode = negativeNode;
	}

    sarNode_p newNode = sar_nodeAddClass_c(currNode, pathChar, nodeClass);
    nwf = sar_buildNodePath_c(newNode, regexp, currPos+1, len, callFunc, nwf, SAR_FALSE);
	return nwf;
}



void sar_buildPath_c(sarNode_p rootNode, const char * regexp, int len, SV * callFunc) {
    sarNodeWithFuncLL_p firstNWF = sar_buildNWFNode_c();
    sar_buildNodePath_c(rootNode, regexp, 0, len, callFunc, firstNWF, SAR_FALSE);
    sar_clearNWFNodes_c(firstNWF);
}


void sar_runCallFunc_c (SV* callFunc, long startPos, long endPos) {
    dSP;

    ENTER;
    SAVETMPS;

    PUSHMARK(SP);
    XPUSHs(sv_2mortal(newSViv(startPos)));
    XPUSHs(sv_2mortal(newSViv(endPos)));
    PUTBACK;

    call_sv(callFunc, G_DISCARD);

    FREETMPS;
    LEAVE;
}


sar_bool sar_checkNodeContainChar_c(sarNode_p checkNode, char checkChar, sar_nodeClass nodeClass) {
	if (nodeClass == SAR_CHAR) {
		if (checkNode->pathChar == checkChar) {
			return SAR_TRUE;
		}
	}
	else if (nodeClass == SAR_DIGIT) {
   		if (isDIGIT(checkChar)) {
   			return SAR_TRUE;
   		}
	}
	else if (nodeClass == SAR_ALPHA_NUM) {
   		if (isALNUM(checkChar)) {
   			return SAR_TRUE;
   		}
	}
	else if (nodeClass == SAR_ALPHA) {
   		if (isALPHA(checkChar)) {
   			return SAR_TRUE;
   		}
	}
	else if (nodeClass == SAR_SPACE) {
   		if (isSPACE(checkChar)) {
   			return SAR_TRUE;
   		}
	}
	else if (nodeClass == SAR_DOT) {
		return SAR_TRUE;
	}

	return SAR_FALSE;
}


sar_bool sar_lookPathPos_c(sarNode_p currNode, const char * checkStr, long startPos, long currPos, long len, sar_bool negative);


sar_bool sar_matchPlusNode_c(sarNode_p nextPlusNode, const char * checkStr, long startPos, long currPos, long len, sar_nodeClass nodeClass, sar_bool negative) {
	sar_bool plusNodesMatched = SAR_FALSE;
	long nextPlusPos = currPos + 1;
	while ( nextPlusPos < len ) {
		char nextPlusChar = checkStr[nextPlusPos];
		sar_bool charMatchNode = sar_checkNodeContainChar_c(nextPlusNode, nextPlusChar, nodeClass);
		if (negative) {
			if (charMatchNode == SAR_FALSE) {
				++nextPlusPos;
			}
			else {
				break;
			}
		}
		else {
			if (charMatchNode == SAR_TRUE) {
				++nextPlusPos;
			}
			else {
				break;
			}
		}

	}

	while (nextPlusPos > currPos) {
		plusNodesMatched = sar_lookPathPos_c(nextPlusNode, checkStr, startPos, nextPlusPos, len, SAR_FALSE);
		if (plusNodesMatched == SAR_TRUE) {
			break;
		}
		--nextPlusPos;
	}

	return plusNodesMatched;
}



sar_bool sar_lookPathPos_c(sarNode_p currNode, const char * checkStr, long startPos, long currPos, long len, sar_bool negative) {
	sar_bool matched = SAR_FALSE;

	int callPos = 0;
    while(currNode->callFunc[callPos] != (SV*)NULL) {
    	matched = SAR_TRUE;
    	sar_runCallFunc_c(currNode->callFunc[callPos], startPos, currPos);
        ++callPos;
    }

    if (currPos >= len) {
    	return matched;
    }

    char checkChar = checkStr[currPos];

    sarNode_p plusNode = currNode->plusNode;
    if (plusNode != (sarNode_p)NULL) {
    	if (negative) {
        	int pathCharNum = 0;
        	for (pathCharNum=0; pathCharNum < plusNode->charNumber; ++pathCharNum) {
        		if (checkChar != plusNode->sarPathChars[pathCharNum]) {
    				sarNode_p nextPlusNode = plusNode->sarNodes[pathCharNum];
    				sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_CHAR, negative);
    				matched = matched || plusNodesMatched;
        		}
        	}

	    	if (plusNode->digitNode != (sarNode_p)NULL) {
	    		if (! isDIGIT(checkChar)) {
	        		sarNode_p nextPlusNode = plusNode->digitNode;
	        		sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_DIGIT, negative);
	        		matched = matched || plusNodesMatched;
	    		}
	    	}

	    	if (plusNode->alphaNumNode != (sarNode_p)NULL) {
	    		if (! isALNUM(checkChar)) {
	        		sarNode_p nextPlusNode = plusNode->alphaNumNode;
	        		sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_ALPHA_NUM, negative);
	        		matched = matched || plusNodesMatched;
	    		}
	    	}

	    	if (plusNode->alphaNode != (sarNode_p)NULL) {
	    		if (! isALPHA(checkChar)) {
	        		sarNode_p nextPlusNode = plusNode->alphaNode;
	        		sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_ALPHA, negative);
	        		matched = matched || plusNodesMatched;
	    		}
	    	}

	    	if (plusNode->spaceNode != (sarNode_p)NULL) {
	    		if (! isSPACE(checkChar)) {
	        		sarNode_p nextPlusNode = plusNode->spaceNode;
	        		sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_SPACE, negative);
	        		matched = matched || plusNodesMatched;
	    		}
	    	}

    	}
    	else {
    		int existListPlusNodePos = sar_searchChar_c(plusNode->sarPathChars, plusNode->charNumber, checkChar);
			if (existListPlusNodePos >= 0) {
				sarNode_p nextPlusNode = plusNode->sarNodes[existListPlusNodePos];
				sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_CHAR, negative);
				matched = matched || plusNodesMatched;
			}

	    	if (plusNode->dotNode != (sarNode_p)NULL) {
	       		sarNode_p nextPlusNode = plusNode->dotNode;
	       		sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_DOT, negative);
	       		matched = matched || plusNodesMatched;
	    	}
	    	if (plusNode->digitNode != (sarNode_p)NULL) {
	    		if (isDIGIT(checkChar)) {
	        		sarNode_p nextPlusNode = plusNode->digitNode;
	        		sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_DIGIT, negative);
	        		matched = matched || plusNodesMatched;
	    		}
	    	}
	    	if (plusNode->alphaNumNode != (sarNode_p)NULL) {
	    		if (isALNUM(checkChar)) {
	        		sarNode_p nextPlusNode = plusNode->alphaNumNode;
	        		sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_ALPHA_NUM, negative);
	        		matched = matched || plusNodesMatched;
	    		}
	    	}
	    	if (plusNode->alphaNode != (sarNode_p)NULL) {
	    		if (isALPHA(checkChar)) {
	        		sarNode_p nextPlusNode = plusNode->alphaNode;
	        		sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_ALPHA, negative);
	        		matched = matched || plusNodesMatched;
	    		}
	    	}
	    	if (plusNode->spaceNode != (sarNode_p)NULL) {
	    		if (isSPACE(checkChar)) {
	        		sarNode_p nextPlusNode = plusNode->spaceNode;
	        		sar_bool plusNodesMatched = sar_matchPlusNode_c(nextPlusNode, checkStr, startPos, currPos, len, SAR_SPACE, negative);
	        		matched = matched || plusNodesMatched;
	    		}
	    	}

    	}
    }

    if (negative) {
    	int pathCharNum = 0;
    	for (pathCharNum=0; pathCharNum < currNode->charNumber; ++pathCharNum) {
    		if (checkChar != currNode->sarPathChars[pathCharNum]) {
    			sar_bool nodesMatched = sar_lookPathPos_c(currNode->sarNodes[pathCharNum], checkStr, startPos, currPos + 1, len, SAR_FALSE);
    			matched = matched || nodesMatched;
    		}
    	}

		if (currNode->spaceNode != (sarNode_p)NULL) {
			if (! isSPACE(checkChar)) {
				sar_bool nodesMatched = sar_lookPathPos_c(currNode->spaceNode, checkStr, startPos, currPos + 1, len, SAR_FALSE);
				matched = matched || nodesMatched;
			}
		}
		if (currNode->digitNode != (sarNode_p)NULL) {
			if (! isDIGIT(checkChar)) {
				sar_bool nodesMatched = sar_lookPathPos_c(currNode->digitNode, checkStr, startPos, currPos + 1, len, SAR_FALSE);
				matched = matched || nodesMatched;
			}
		}
		if (currNode->alphaNumNode != (sarNode_p)NULL) {
			if (! isALNUM(checkChar)) {
				sar_bool nodesMatched = sar_lookPathPos_c(currNode->alphaNumNode, checkStr, startPos, currPos + 1, len, SAR_FALSE);
				matched = matched || nodesMatched;
			}
		}
		if (currNode->alphaNode != (sarNode_p)NULL) {
			if (! isALPHA(checkChar)) {
				sar_bool nodesMatched = sar_lookPathPos_c(currNode->alphaNode, checkStr, startPos, currPos + 1, len, SAR_FALSE);
				matched = matched || nodesMatched;
			}
		}

    }
    else {
		int existListNodePos = sar_searchChar_c(currNode->sarPathChars, currNode->charNumber, checkChar);
		if (existListNodePos >= 0) {
			sar_bool nodesMatched = sar_lookPathPos_c(currNode->sarNodes[existListNodePos], checkStr, startPos, currPos + 1, len, SAR_FALSE);
			matched = matched || nodesMatched;
		}

		if (currNode->negativeNode != (sarNode_p)NULL) {
			sar_bool nodesMatched = sar_lookPathPos_c(currNode->negativeNode, checkStr, startPos, currPos, len, SAR_TRUE);
			matched = matched || nodesMatched;
		}

		if (currNode->dotNode != (sarNode_p)NULL) {
			sar_bool nodesMatched = sar_lookPathPos_c(currNode->dotNode, checkStr, startPos, currPos + 1, len, SAR_FALSE);
			matched = matched || nodesMatched;
		}
		if (currNode->spaceNode != (sarNode_p)NULL) {
			if (isSPACE(checkChar)) {
				sar_bool nodesMatched = sar_lookPathPos_c(currNode->spaceNode, checkStr, startPos, currPos + 1, len, SAR_FALSE);
				matched = matched || nodesMatched;
			}
		}
		if (currNode->digitNode != (sarNode_p)NULL) {
			if (isDIGIT(checkChar)) {
				sar_bool nodesMatched = sar_lookPathPos_c(currNode->digitNode, checkStr, startPos, currPos + 1, len, SAR_FALSE);
				matched = matched || nodesMatched;
			}
		}
		if (currNode->alphaNumNode != (sarNode_p)NULL) {
			if (isALNUM(checkChar)) {
				sar_bool nodesMatched = sar_lookPathPos_c(currNode->alphaNumNode, checkStr, startPos, currPos + 1, len, SAR_FALSE);
				matched = matched || nodesMatched;
			}
		}
		if (currNode->alphaNode != (sarNode_p)NULL) {
			if (isALPHA(checkChar)) {
				sar_bool nodesMatched = sar_lookPathPos_c(currNode->alphaNode, checkStr, startPos, currPos + 1, len, SAR_FALSE);
				matched = matched || nodesMatched;
			}
		}

    }

    return matched;
}


void sar_lookPath_c(sarRootNode_p rootNode, const char * checkStr, long len, long startPos) {
    sarNode_p node = rootNode->sarNode;
    rootNode->procFlags = 0;

	long currPos=startPos;
	while(currPos<len) {
		sar_lookPathPos_c(node, checkStr, currPos, currPos, len, SAR_FALSE);
		if (rootNode->procFlags == SAR_STOP_MATCH) {
			rootNode->procFlags = 0;
			break;
		}
		else if (rootNode->procFlags == SAR_PROC_FROM) {
			rootNode->procFlags = 0;
			currPos = rootNode->continueFrom;
		}
		else {
			++currPos;
		}
	}

	rootNode->procFlags = 0;
}


void sar_lookPathFromPos_c(sarNode_p rootNode, long pos, const char * checkStr, long len) {
	sar_lookPathPos_c(rootNode, checkStr, pos, pos, len, SAR_FALSE);
}




