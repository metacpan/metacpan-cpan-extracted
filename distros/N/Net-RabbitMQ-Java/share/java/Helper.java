import java.lang.ref.WeakReference;
import java.util.*;
import org.perl.inline.java.*;
import com.rabbitmq.client.*;

class Helper {
    public Helper () {}
    
    public class Callback
    {
        public String callbackId;
        public Object args[];
        
        public Callback (String callbackId, Object args[]) {
            this.callbackId = callbackId;
            this.args = args;
        }
    }
    
    class CallbackCaller extends InlineJavaPerlCaller
    {
        private ArrayList<Callback> callbackQueue = new ArrayList<Callback>();
        private WeakReference<GenericListener> listener;
        
        public CallbackCaller(GenericListener listener)
            throws InlineJavaException {
            this.listener = new WeakReference<GenericListener>(listener);
        }
        
        public void Enqueue (Callback cb) {
            callbackQueue.add(cb);
        }
        
        public void process () {
            Iterator i = callbackQueue.iterator();
            while (i.hasNext()) {
                Callback cb = (Callback)i.next();
                this.Call(cb);
            }
            callbackQueue.clear();
        }
        
        public GenericListener getListener() {
            return this.listener.get();
        }
        
        private void Call (Callback cb) {
            try {
                CallPerlSub("Net::RabbitMQ::Java::_callback", 
                    new Object [] { cb.callbackId, cb.args});
            } catch (InlineJavaPerlException e) {
                relayException(e);
            } catch (InlineJavaException e) {
                relayException(e);
            }
        }
        
        private void relayException (Exception e)
        {
            try {
                CallPerlSub("Net::RabbitMQ::Java::_callback_error",
                    new Object [] {e.getMessage()});
            } catch (Exception e2) {}
        }
        
        protected void finalize() throws Throwable {
            CloseCallbackStream();
        }
    }
    
    abstract public class GenericListener
    {
        private String callbackId;
        private CallbackCaller cc;
        
        public GenericListener(String c) throws InlineJavaException {
            cc = new CallbackCaller (this);
            callbackId = c;
        }
        
        protected void CreateCallback (Object args[])
        {
            Callback cb = new Callback(callbackId, args);
            cc.Enqueue(cb);
        }
        
        public CallbackCaller getCallbackCaller() {
            return cc;
        }
    }
    
    public class ReturnListener extends GenericListener
        implements com.rabbitmq.client.ReturnListener {
        
        public ReturnListener(String c) throws InlineJavaException {
            super(c);
        }
        
        public void handleBasicReturn(int replyCode, 
                        String replyText, 
                        String exchange, 
                        String routingKey, 
                        AMQP.BasicProperties properties, 
                        byte[] body) throws java.io.IOException {
            CreateCallback(new Object [] {
                replyCode, replyText, exchange, routingKey, properties, body
            });
        }
    }
    
    public class ConfirmListener extends GenericListener
        implements com.rabbitmq.client.ConfirmListener {
        
        public ConfirmListener(String c) throws InlineJavaException {
            super(c);
        }
        
        public void handleAck(long deliveryTag, boolean multiple) throws java.io.IOException {
            CreateCallback(new Object [] { "ack", deliveryTag, multiple });
        }
        
        public void handleNack(long deliveryTag, boolean multiple) throws java.io.IOException {
            CreateCallback(new Object [] { "nack", deliveryTag, multiple });
        }
    }
    
    public class ShutdownListener extends GenericListener
        implements com.rabbitmq.client.ShutdownListener {
        
        public ShutdownListener(String c) throws InlineJavaException {
            super(c);
        }
        
        public void shutdownCompleted(ShutdownSignalException cause) {
            CreateCallback(new Object [] { cause });
        }
    }

    public class FlowListener extends GenericListener
        implements com.rabbitmq.client.FlowListener {
        
        public FlowListener(String c) throws InlineJavaException {
            super(c);
        }
        
        public void handleFlow(boolean active) throws java.io.IOException {
            CreateCallback(new Object [] { active });
        }
    }
    
}
