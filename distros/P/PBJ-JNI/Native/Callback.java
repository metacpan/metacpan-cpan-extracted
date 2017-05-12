/* 
 * Copyright (c) 2001 Ping Liang
 * All rights reserved.
 *
 * This program is free software; you can use, redistribute and/or
 * modify it under the same terms as Perl itself.
 *
 * $Id: Callback.java,v 1.1 2002/01/01 20:40:29 liang Exp $
 */

public class Callback {
    public static native void callback(String method, Object obj);
    static {
	System.loadLibrary("Callback");
    }
}
